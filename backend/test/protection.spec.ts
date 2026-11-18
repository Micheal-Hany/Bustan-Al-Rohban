import { generateKeyPairSync } from 'node:crypto';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import fs from 'node:fs';
import type { INestApplication } from '@nestjs/common';
import { Logger } from '@nestjs/common';
import request from 'supertest';
import { ConfigError, protectionFromEnv } from '../src/common/config';
import { createApp } from '../src/create-app';
import { FakeLlmProvider } from '../src/providers/fake-llm';
import { FetchFn } from '../src/providers/http';
import {
  PlayIntegrityVerifier, TestAttestation, nonceFor, serviceAccountTokenProvider,
} from '../src/protection/attestation';
import { RateLimiter } from '../src/protection/rate-limiter';
import { SpendGuard } from '../src/protection/spend-guard';
import { testConfig, testProtection } from './helpers';

const Q = 'ماذا يقول الكتاب عن الصوم والانقطاع عن الطعام؟';
const INST = 'inst-0123456789abcdef';
const chat = (over: Record<string, unknown> = {}) => ({
  mode: 'book_scope', scope: {}, messages: [{ role: 'user', text: Q }], ...over,
});

describe('RateLimiter', () => {
  it('allows max hits per window, then returns wait seconds, then resets', () => {
    let t = 1_000_000;
    const rl = new RateLimiter({ max: 2, windowSeconds: 60 }, () => t);
    expect(rl.hit('a')).toBeNull();
    expect(rl.hit('a')).toBeNull();
    expect(rl.hit('a')).toBe(60);
    t += 30_000;
    expect(rl.hit('a')).toBe(30);
    expect(rl.hit('b')).toBeNull(); // keys are independent
    t += 30_000;
    expect(rl.hit('a')).toBeNull(); // new window
  });
  it('sweeps expired keys so memory stays bounded', () => {
    let t = 0;
    const rl = new RateLimiter({ max: 1, windowSeconds: 1 }, () => t);
    for (let i = 0; i < 499; i++) rl.hit(`k${i}`);
    t += 5000;
    rl.hit('x'); // 500th call triggers the sweep
    expect(rl.size).toBeLessThan(5);
  });
});

describe('SpendGuard', () => {
  const cfg = { dailyCapUsd: 1, unknownCostUsd: 0.4, killSwitch: false, maxConcurrentModelCalls: 2 };
  const est = (usd: number) => ({ status: 'estimated' as const, amountUsd: usd, pricingVersion: 'v' });
  it('trips at the cap and resets on the next UTC day', () => {
    let t = Date.UTC(2026, 10, 18, 12);
    const g = new SpendGuard(cfg, () => t);
    g.acquire(); g.release(); g.record(est(0.6));
    g.acquire(); g.release(); g.record(est(0.5));
    expect(() => g.acquire()).toThrow(expect.objectContaining({ code: 'temporarily_unavailable' }));
    t = Date.UTC(2026, 10, 19, 0, 0, 1);
    expect(() => g.acquire()).not.toThrow();
    expect(g.snapshot().spentUsd).toBe(0);
  });
  it('charges the unknown-cost amount when cost is unavailable (cap cannot be bypassed)', () => {
    const g = new SpendGuard(cfg);
    g.record({ status: 'unavailable', amountUsd: null, pricingVersion: 'v', reason: 'no_pricing' });
    g.record(undefined);
    expect(g.snapshot().spentUsd).toBe(0.8);
  });
  it('kill switch refuses every model call', () => {
    expect(() => new SpendGuard({ ...cfg, killSwitch: true }).acquire()).toThrow(expect.objectContaining({ code: 'temporarily_unavailable' }));
  });
  it('bounds concurrent model calls', () => {
    const g = new SpendGuard(cfg);
    g.acquire(); g.acquire();
    expect(() => g.acquire()).toThrow(expect.objectContaining({ code: 'busy' }));
    g.release();
    expect(() => g.acquire()).not.toThrow();
  });
});

describe('attestation verifiers', () => {
  it('test mode accepts only the configured token', async () => {
    const v = new TestAttestation('tok');
    expect(await v.verify('tok', undefined)).toEqual({ ok: true });
    expect(await v.verify('bad', undefined)).toEqual({ ok: false, reason: 'invalid' });
    expect(await v.verify(undefined, undefined)).toEqual({ ok: false, reason: 'missing' });
  });

  describe('Play Integrity (mocked Google)', () => {
    const NOW = 1_800_000_000_000;
    const good = (over: Record<string, unknown> = {}) => ({
      tokenPayloadExternal: {
        requestDetails: { requestPackageName: 'com.example.bustan', nonce: nonceFor('req-1'), timestampMillis: String(NOW - 1000) },
        appIntegrity: { appRecognitionVerdict: 'PLAY_RECOGNIZED', packageName: 'com.example.bustan', certificateSha256Digest: ['CERT1'] },
        deviceIntegrity: { deviceRecognitionVerdict: ['MEETS_DEVICE_INTEGRITY'] },
        ...over,
      },
    });
    const make = (res: () => Response | Promise<Response>, certDigests: string[] = []) =>
      new PlayIntegrityVerifier({
        packageName: 'com.example.bustan', certDigests, maxTokenAgeSeconds: 300, now: () => NOW,
        accessToken: () => Promise.resolve('oauth'),
        fetchFn: (() => Promise.resolve(res())) as unknown as FetchFn,
      });
    const ok = (b: unknown) => () => new Response(JSON.stringify(b), { status: 200 });

    it('accepts a good verdict bound to the request id', async () => {
      expect(await make(ok(good())).verify('t', 'req-1')).toEqual({ ok: true });
      expect(await make(ok(good()), ['CERT1']).verify('t', 'req-1')).toEqual({ ok: true });
    });
    it.each([
      ['wrong nonce (replay for another request)', good(), 'req-OTHER'],
      ['wrong package', good({ requestDetails: { requestPackageName: 'evil.app', nonce: nonceFor('req-1'), timestampMillis: String(NOW) } }), 'req-1'],
      ['stale token', good({ requestDetails: { requestPackageName: 'com.example.bustan', nonce: nonceFor('req-1'), timestampMillis: String(NOW - 3_600_000) } }), 'req-1'],
      ['unrecognised app (sideloaded)', good({ appIntegrity: { appRecognitionVerdict: 'UNRECOGNIZED_VERSION', packageName: 'com.example.bustan' } }), 'req-1'],
      ['device fails integrity', good({ deviceIntegrity: { deviceRecognitionVerdict: [] } }), 'req-1'],
    ])('rejects %s', async (_n, body, rid) => {
      expect(await make(ok(body)).verify('t', rid)).toEqual({ ok: false, reason: 'invalid' });
    });
    it('rejects a certificate that is not on the allow-list', async () => {
      expect(await make(ok(good()), ['OTHER']).verify('t', 'req-1')).toEqual({ ok: false, reason: 'invalid' });
    });
    it('requires a token and a request id', async () => {
      expect(await make(ok(good())).verify(undefined, 'req-1')).toEqual({ ok: false, reason: 'missing' });
      expect(await make(ok(good())).verify('t', undefined)).toEqual({ ok: false, reason: 'invalid' });
    });
    it('treats Google 400 as invalid and Google outages as unavailable (fail closed)', async () => {
      expect(await make(() => new Response('', { status: 400 })).verify('t', 'req-1')).toEqual({ ok: false, reason: 'invalid' });
      expect(await make(() => new Response('', { status: 500 })).verify('t', 'req-1')).toEqual({ ok: false, reason: 'unavailable' });
      expect(await make(() => Promise.reject(new Error('net'))).verify('t', 'req-1')).toEqual({ ok: false, reason: 'unavailable' });
    });
  });

  it('service-account token provider signs a JWT, caches and refreshes', async () => {
    const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
    const dir = mkdtempSync(join(tmpdir(), 'sa-'));
    const file = join(dir, 'sa.json');
    writeFileSync(file, JSON.stringify({ client_email: 'svc@x.iam', private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }) }));
    let t = 0, calls = 0;
    const f = ((_u: string, init: RequestInit) => {
      calls++;
      const assertion = new URLSearchParams(String(init.body)).get('assertion') as string;
      expect(assertion.split('.')).toHaveLength(3);
      return Promise.resolve(new Response(JSON.stringify({ access_token: `a${calls}`, expires_in: 3600 }), { status: 200 }));
    }) as unknown as FetchFn;
    const get = serviceAccountTokenProvider(file, f, () => t);
    expect(await get()).toBe('a1');
    expect(await get()).toBe('a1');
    t += 3_600_000;
    expect(await get()).toBe('a2');
    expect(calls).toBe(2);
  });
});

describe('protection config', () => {
  it('has proposed defaults and validates modes', () => {
    const p = protectionFromEnv({});
    expect(p).toMatchObject({ attestation: { mode: 'off' }, dailyCapUsd: 5, killSwitch: false });
    expect(protectionFromEnv({ AI_KILL_SWITCH: 'true' }).killSwitch).toBe(true);
    expect(() => protectionFromEnv({ ATTESTATION_MODE: 'nope' })).toThrow(ConfigError);
    expect(() => protectionFromEnv({ ATTESTATION_MODE: 'test' })).toThrow(ConfigError);
    expect(() => protectionFromEnv({ ATTESTATION_MODE: 'play_integrity' })).toThrow(ConfigError);
    expect(() => protectionFromEnv({ DAILY_SPEND_CAP_USD: '0' })).toThrow(ConfigError);
  });
});

describe('HTTP protection', () => {
  const open: INestApplication[] = [];
  const boot = async (protection = {}, llm = new FakeLlmProvider(), cfg = {}) => {
    const app = await createApp(testConfig({ protection: testProtection(protection), ...cfg }), false, llm);
    await app.init();
    open.push(app);
    return { app, llm, http: () => request(app.getHttpServer()) };
  };
  afterEach(async () => { while (open.length) await open.pop()?.close(); });

  it('per-IP limit trips with 429, Retry-After and a fixed body', async () => {
    const { http } = await boot({ ipLimit: { max: 2, windowSeconds: 600 } });
    await http().post('/v1/chat').send(chat()).expect(200);
    await http().post('/v1/chat').send(chat()).expect(200);
    const res = await http().post('/v1/chat').send(chat()).expect(429);
    expect(res.body.error).toMatchObject({ code: 'rate_limited', retryAfterSeconds: expect.any(Number) });
    expect(Number(res.headers['retry-after'])).toBeGreaterThan(0);
    expect(JSON.stringify(res.body)).not.toContain('الصوم');
  });
  it('per-installation limit trips for that installation only', async () => {
    const { http } = await boot({ installationLimit: { max: 1, windowSeconds: 600 } });
    await http().post('/v1/chat').send(chat({ installationId: INST })).expect(200);
    await http().post('/v1/chat').send(chat({ installationId: INST })).expect(429);
    await http().post('/v1/chat').send(chat({ installationId: 'other-0123456789abcd' })).expect(200);
  });
  it('rejects a malformed installation id', async () => {
    const { http } = await boot();
    await http().post('/v1/chat').send(chat({ installationId: 'short' })).expect(400);
  });
  it('refuses an oversized body with 413 and too many messages with 400', async () => {
    const { http } = await boot();
    const big = await http().post('/v1/chat').send(chat({ pad: 'x'.repeat(70_000) })).expect(413);
    expect(big.body.error.code).toBe('request_too_large');
    const many = Array.from({ length: 21 }, () => ({ role: 'user', text: 'س' }));
    await http().post('/v1/chat').send(chat({ messages: many })).expect(400);
    const bad = await http().post('/v1/chat').set('content-type', 'application/json').send('{not json').expect(400);
    expect(bad.body.error.code).toBe('invalid_request');
  });

  describe('attestation (test mode)', () => {
    const att = { attestation: { mode: 'test' as const, testToken: 'good-token', certDigests: [], maxTokenAgeSeconds: 300 } };
    it('rejects a request without a token, and with a wrong token', async () => {
      const { http, llm } = await boot(att);
      const a = await http().post('/v1/chat').send(chat()).expect(403);
      expect(a.body.error.code).toBe('attestation_required');
      const b = await http().post('/v1/chat').send(chat({ attestationToken: 'nope' })).expect(403);
      expect(b.body.error.code).toBe('attestation_failed');
      expect(llm.calls).toBe(0);
    });
    it('serves a request with the right token', async () => {
      const { http } = await boot(att);
      await http().post('/v1/chat').send(chat({ attestationToken: 'good-token' })).expect(200);
    });
    it('also protects the report endpoint', async () => {
      const { http } = await boot(att);
      await http().post('/v1/reports').send(reportBody()).expect(403);
    });
  });

  describe('spend cap and kill switch', () => {
    it('cap reached -> friendly 503 temporarily_unavailable, model not called again', async () => {
      // fake cost is unknown (no price for fake:fake-1 in prod table) -> unknownCostUsd per call
      const { http, llm } = await boot({ dailyCapUsd: 0.05, unknownCostUsd: 0.03 }, new FakeLlmProvider(), {
        pricingFile: join(__dirname, '..', 'config', 'pricing.json'),
      });
      await http().post('/v1/chat').send(chat()).expect(200);
      await http().post('/v1/chat').send(chat()).expect(200); // 0.03 < 0.05 at check time
      const res = await http().post('/v1/chat').send(chat()).expect(503);
      expect(res.body.error.code).toBe('temporarily_unavailable');
      expect(llm.calls).toBe(2);
    });
    it('kill switch returns 503 for model paths but safety and refusals still work', async () => {
      const { http, llm } = await boot({ killSwitch: true });
      await http().post('/v1/chat').send(chat()).expect(503);
      const safety = await http().post('/v1/chat').send(chat({ messages: [{ role: 'user', text: 'حللني من خطاياي' }] })).expect(200);
      expect(safety.body.status).toBe('safety');
      const refused = await http().post('/v1/chat').send(chat({ messages: [{ role: 'user', text: 'ما هي عاصمة فرنسا؟' }] })).expect(200);
      expect(refused.body.status).toBe('refused');
      expect(llm.calls).toBe(0);
    });
  });
});

const reportBody = (over: Record<string, unknown> = {}) => ({
  reason: 'wrong_or_invented',
  note: 'ملاحظة سرية للاختبار',
  answerText: 'نص الإجابة المبلغ عنها',
  question: 'سؤال المستخدم السري',
  citedParagraphIds: ['p-000001'],
  contentVersion: 7,
  provider: 'fake',
  model: 'fake-1',
  ...over,
});

describe('report endpoint stub', () => {
  let app: INestApplication;
  beforeAll(async () => { app = await createApp(testConfig(), false); await app.init(); });
  afterAll(() => app.close());
  const http = () => request(app.getHttpServer());

  it('acknowledges a valid report but stores nothing', async () => {
    const res = await http().post('/v1/reports').send(reportBody()).expect(202);
    expect(res.body).toEqual({ reportId: expect.any(String), stored: false });
  });
  it('rejects extra fields (e.g. conversation history) and bad reasons', async () => {
    await http().post('/v1/reports').send(reportBody({ messages: [{ role: 'user', text: 'x' }] })).expect(400);
    await http().post('/v1/reports').send(reportBody({ reason: 'whatever' })).expect(400);
    await http().post('/v1/reports').send(reportBody({ note: 'x'.repeat(501) })).expect(400);
  });
});

describe('privacy-safe logging and no storage', () => {
  it('no chat, report or token text reaches any log level, and nothing is written to disk', async () => {
    const out: string[] = [];
    const capture = (...a: unknown[]): void => void out.push(a.map(String).join(' '));
    const spies = (['log', 'error', 'warn', 'debug', 'verbose', 'fatal'] as const).map((l) => jest.spyOn(Logger.prototype, l).mockImplementation(capture));
    const writes = [jest.spyOn(fs, 'writeFileSync'), jest.spyOn(fs, 'appendFileSync'), jest.spyOn(fs, 'createWriteStream')];
    const SECRET_Q = 'سؤال سري جدا عن الصوم والانقطاع عن الطعام';
    const app = await createApp(
      testConfig({ protection: testProtection({ ipLimit: { max: 6, windowSeconds: 600 }, attestation: { mode: 'test', testToken: 'TOKEN-SECRET-XYZ', certDigests: [], maxTokenAgeSeconds: 300 } }) }),
      ['log', 'warn', 'error', 'debug', 'verbose'],
      new FakeLlmProvider(),
    );
    await app.init();
    const http = () => request(app.getHttpServer());
    const msg = (t: string) => ({ messages: [{ role: 'user', text: t }] });
    const ok = { attestationToken: 'TOKEN-SECRET-XYZ', installationId: INST };
    await http().post('/v1/chat').send(chat({ ...ok, ...msg(SECRET_Q) }));          // answered
    await http().post('/v1/chat').send(chat({ ...ok, ...msg('حللني من خطاياي سرا') })); // safety
    await http().post('/v1/chat').send(chat({ ...ok, ...msg('عاصمة فرنسا السرية؟') })); // refusal
    await http().post('/v1/chat').send(chat({ ...msg(SECRET_Q), attestationToken: 'WRONG-TOKEN-SECRET' })); // 403
    await http().post('/v1/chat').send({ bad: SECRET_Q });                           // 400
    await http().post('/v1/reports').send(reportBody({ ...ok }));                    // report
    await http().post('/v1/chat').send(chat({ ...ok, ...msg(SECRET_Q) }));          // 429 (7th hit)
    await app.close();
    const all = out.join('\n');
    for (const secret of ['سري', 'السرية', 'TOKEN-SECRET-XYZ', 'WRONG-TOKEN-SECRET', 'نص الإجابة المبلغ', 'ملاحظة سرية', 'الصوم']) {
      expect(all).not.toContain(secret);
    }
    expect(all).toContain('"event":"chat"');
    expect(all).toContain('"event":"report"');
    for (const w of writes) expect(w).not.toHaveBeenCalled();
    [...spies, ...writes].forEach((s) => s.mockRestore());
  });
});
