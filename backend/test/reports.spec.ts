import { mkdtempSync, readFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import type { INestApplication } from '@nestjs/common';
import { Logger } from '@nestjs/common';
import request from 'supertest';
import { createApp } from '../src/create-app';
import { FileReportStore, InMemoryReportStore } from '../src/reports/report.store';
import { testConfig, testProtection } from './helpers';

const body = (over: Record<string, unknown> = {}) => ({
  reason: 'wrong_or_invented',
  note: 'ملاحظة',
  answerText: 'نص الإجابة المبلغ عنها',
  question: 'سؤال المستخدم',
  citedParagraphIds: ['p-000001', 'p-000002'],
  contentVersion: 7,
  provider: 'openai',
  model: 'test-model',
  ...over,
});

describe('POST /v1/reports', () => {
  const open: INestApplication[] = [];
  const boot = async (store?: InMemoryReportStore, cfg = {}, deps = {}) => {
    const app = await createApp(testConfig(cfg), false, undefined, { reportStore: store, ...deps });
    await app.init();
    open.push(app);
    return request(app.getHttpServer());
  };
  afterEach(async () => {
    while (open.length) await open.pop()?.close();
  });

  it('stores exactly the report fields and nothing else (no history, ids, IP or token)', async () => {
    const store = new InMemoryReportStore();
    const http = await boot(store, { protection: testProtection({ attestation: { mode: 'test', testToken: 'T', certDigests: [], maxTokenAgeSeconds: 300 } }) });
    const res = await http
      .post('/v1/reports')
      .send({ ...body(), installationId: 'inst-0123456789abcdef', attestationToken: 'T', requestId: 'req-1' })
      .expect(202);
    expect(res.body).toEqual({ reportId: expect.any(String), stored: true });
    const rec = store.items[0];
    expect(Object.keys(rec).sort()).toEqual(
      ['answerText', 'citedParagraphIds', 'contentVersion', 'id', 'model', 'note', 'provider', 'question', 'reason', 'receivedAt'].sort(),
    );
    expect(rec).toMatchObject({ id: res.body.reportId, question: 'سؤال المستخدم', reason: 'wrong_or_invented', citedParagraphIds: ['p-000001', 'p-000002'] });
    const text = JSON.stringify(rec);
    expect(text).not.toContain('inst-0123456789abcdef');
    expect(text).not.toContain('"T"');
    expect(text).not.toMatch(/127\.0\.0\.1|::1/);
  });

  it('omits an empty note and rejects conversation history or unknown fields', async () => {
    const store = new InMemoryReportStore();
    const http = await boot(store);
    await http.post('/v1/reports').send(body({ note: '' })).expect(202);
    expect('note' in store.items[0]).toBe(false);
    await http.post('/v1/reports').send(body({ messages: [{ role: 'user', text: 'x' }] })).expect(400);
    await http.post('/v1/reports').send(body({ history: ['x'] })).expect(400);
    await http.post('/v1/reports').send(body({ reason: 'nope' })).expect(400);
    await http.post('/v1/reports').send(body({ answerText: 'x'.repeat(6001) })).expect(400);
    await http.post('/v1/reports').send(body({ citedParagraphIds: Array(21).fill('p-1') })).expect(400);
    expect(store.items).toHaveLength(1);
  });

  it('answers 503 and keeps nothing when no store is configured', async () => {
    const http = await boot(undefined);
    const res = await http.post('/v1/reports').send(body()).expect(503);
    expect(res.body.error.code).toBe('reports_unavailable');
  });

  it('is protected by attestation and the rate limits', async () => {
    const store = new InMemoryReportStore();
    const http = await boot(store, {
      protection: testProtection({
        ipLimit: { max: 1, windowSeconds: 600 },
        attestation: { mode: 'test', testToken: 'T', certDigests: [], maxTokenAgeSeconds: 300 },
      }),
    });
    await http.post('/v1/reports').send(body({ attestationToken: 'wrong' })).expect(403);
    await http.post('/v1/reports').send(body({ attestationToken: 'T' })).expect(429); // IP limit of 1 already used
    expect(store.items).toHaveLength(0);
  });

  it('does not log report text', async () => {
    const out: string[] = [];
    const spy = jest.spyOn(Logger.prototype, 'log').mockImplementation((m: unknown) => void out.push(String(m)));
    const http = await boot(new InMemoryReportStore());
    await http.post('/v1/reports').send(body()).expect(202);
    spy.mockRestore();
    const all = out.join('\n');
    expect(all).toContain('"event":"report"');
    for (const secret of ['نص الإجابة', 'سؤال المستخدم', 'ملاحظة']) expect(all).not.toContain(secret);
  });

  it('a store failure is a generic 500 without report text', async () => {
    const failing = { add: () => Promise.reject(new Error('disk full: سؤال المستخدم')), list: () => Promise.resolve([]) };
    const app = await createApp(testConfig(), false, undefined, { reportStore: failing });
    await app.init();
    open.push(app);
    const res = await request(app.getHttpServer()).post('/v1/reports').send(body()).expect(500);
    expect(JSON.stringify(res.body)).not.toContain('سؤال المستخدم');
  });

  it('works with the real file store (config REPORTS_FILE)', async () => {
    const file = join(mkdtempSync(join(tmpdir(), 'rep-')), 'sub', 'reports.jsonl');
    const http = await boot(undefined, { reportsFile: file });
    await http.post('/v1/reports').send(body()).expect(202);
    await http.post('/v1/reports').send(body({ reason: 'other' })).expect(202);
    const lines = readFileSync(file, 'utf8').trim().split('\n');
    expect(lines).toHaveLength(2);
    expect(JSON.parse(lines[1]).reason).toBe('other');
    expect(await new FileReportStore(file).list()).toHaveLength(2);
  });
});

describe('FileReportStore', () => {
  it('lists nothing when the file does not exist and creates no file by listing', async () => {
    const file = join(mkdtempSync(join(tmpdir(), 'rep-')), 'none.jsonl');
    expect(await new FileReportStore(file).list()).toEqual([]);
    expect(existsSync(file)).toBe(false);
  });
});

describe('no analytics or crash-reporting SDK in the backend', () => {
  it('package.json has no telemetry dependency', () => {
    const pkg = JSON.parse(readFileSync(join(__dirname, '..', 'package.json'), 'utf8')) as {
      dependencies: Record<string, string>;
      devDependencies: Record<string, string>;
    };
    const names = Object.keys({ ...pkg.dependencies, ...pkg.devDependencies }).join(' ');
    expect(names).not.toMatch(/sentry|bugsnag|rollbar|datadog|newrelic|mixpanel|segment|amplitude|posthog|crashlytics|appinsights|opentelemetry|honeybadger/i);
  });
});

