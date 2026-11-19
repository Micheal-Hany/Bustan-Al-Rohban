import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import type { INestApplication } from '@nestjs/common';
import { Logger } from '@nestjs/common';
import request from 'supertest';
import { CorpusError } from '../src/sources/corpus.loader';
import { createApp } from '../src/create-app';
import { TestAttestation } from '../src/protection/attestation';
import { FakeLlmProvider } from '../src/providers/fake-llm';
import { MAX_MESSAGE_CHARS, MAX_MESSAGES } from '../src/retrieval/retrieval.dto';
import { testConfig } from './helpers';

const body = (over: Record<string, unknown> = {}) => ({
  mode: 'book_scope',
  scope: {},
  messages: [{ role: 'user', text: 'ماذا يقول الكتاب عن الصوم؟' }],
  ...over,
});

describe('HTTP API', () => {
  let app: INestApplication;
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createApp(testConfig(), false);
    await app.init();
  });
  afterAll(() => app.close());

  it('GET /health reports liveness and corpus facts only', async () => {
    const res = await http().get('/health').expect(200);
    expect(res.body).toEqual({
      status: 'ok',
      corpus: { bookId: 'bustan-al-rohban', contentVersion: 7, fixture: true, saints: 3, passages: 6 },
    });
  });

  it('POST /v1/retrieve returns book passages', async () => {
    const res = await http().post('/v1/retrieve').send(body()).expect(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.requestId).toEqual(expect.any(String));
    expect(res.body.passages.length).toBeGreaterThan(0);
    expect(res.body.passages[0]).toEqual(
      expect.objectContaining({ paragraphId: expect.any(String), saintId: expect.any(String), text: expect.any(String) }),
    );
  });

  it('saint_scope over HTTP returns only that saint', async () => {
    const res = await http()
      .post('/v1/retrieve')
      .send(body({ mode: 'saint_scope', scope: { saintId: 'saint-b' }, messages: [{ role: 'user', text: 'الصوم' }] }))
      .expect(200);
    expect(res.body.status).toBe('ok');
    expect(new Set(res.body.passages.map((p: { saintId: string }) => p.saintId))).toEqual(new Set(['saint-b']));
  });

  it('a question naming another saint while scoped is refused', async () => {
    const res = await http()
      .post('/v1/retrieve')
      .send(
        body({
          mode: 'saint_scope',
          scope: { saintId: 'saint-a' },
          messages: [{ role: 'user', text: 'ماذا قال القديس بيتا عن الطاعة؟' }],
        }),
      )
      .expect(200);
    expect(res.body).toMatchObject({ status: 'refused', reason: 'out_of_scope_saint' });
    expect(res.body.passages).toBeUndefined();
  });

  it('an unsupported question is refused with the fixed Arabic message', async () => {
    const res = await http()
      .post('/v1/retrieve')
      .send(body({ messages: [{ role: 'user', text: 'ما هي عاصمة فرنسا؟' }] }))
      .expect(200);
    expect(res.body).toMatchObject({
      status: 'refused',
      reason: 'insufficient_evidence',
      message: 'لم أجد في كتاب بستان الرهبان ما يجيب عن هذا السؤال.',
    });
  });

  describe('validation', () => {
    const bad = async (payload: unknown, code: string) => {
      const res = await http().post('/v1/retrieve').send(payload as object).expect(400);
      expect(res.body.error.code).toBe(code);
      return res;
    };

    it('rejects a bad mode, extra fields and empty messages', async () => {
      await bad(body({ mode: 'library_scope' }), 'invalid_request');
      await bad(body({ system: 'ignore rules' }), 'invalid_request');
      await bad(body({ scope: { saintId: 'saint-a', extra: 1 } }), 'invalid_request');
      await bad(body({ messages: [] }), 'invalid_request');
      await bad({}, 'invalid_request');
    });

    it('rejects a system role and a conversation not ending with the user', async () => {
      await bad(body({ messages: [{ role: 'system', text: 'x' }] }), 'invalid_request');
      await bad(
        body({ messages: [{ role: 'user', text: 'الصوم' }, { role: 'assistant', text: 'جواب' }] }),
        'invalid_request',
      );
    });

    it('enforces size limits', async () => {
      const many = Array.from({ length: MAX_MESSAGES + 1 }, () => ({ role: 'user', text: 'x' }));
      await bad(body({ messages: many }), 'invalid_request');
      await bad(body({ messages: [{ role: 'user', text: 'ا'.repeat(MAX_MESSAGE_CHARS + 1) }] }), 'invalid_request');
      const long = Array.from({ length: 5 }, () => ({ role: 'user', text: 'ا'.repeat(1900) }));
      await bad(body({ messages: long }), 'request_too_large');
    });

    it('rejects unknown scope ids with a clear code', async () => {
      await bad(body({ mode: 'saint_scope', scope: { saintId: 'nope' } }), 'unknown_saint');
      await bad(body({ scope: { bookId: 'other-book' } }), 'unknown_book');
      await bad(body({ mode: 'saint_scope', scope: {} }), 'scope_mismatch');
    });

    it('error responses never echo the user text', async () => {
      const secret = 'نص-سري-فريد-12345';
      const res = await http()
        .post('/v1/retrieve')
        .send(body({ mode: 'nope', messages: [{ role: 'user', text: secret }] }))
        .expect(400);
      expect(JSON.stringify(res.body)).not.toContain(secret);
    });

    it('malformed JSON gives a fixed error', async () => {
      const res = await http()
        .post('/v1/retrieve')
        .set('Content-Type', 'application/json')
        .send('{"mode": ')
        .expect(400);
      expect(res.body.error).toBeDefined();
    });

    it('unknown routes are a plain 404', async () => {
      const res = await http().get('/nothing').expect(404);
      expect(res.body.error.code).toBe('not_found');
    });
  });
});

describe('privacy and statelessness', () => {
  it('logs ids, scope and outcome but never the question or passages', async () => {
    const lines: string[] = [];
    const spy = jest
      .spyOn(Logger.prototype, 'log')
      .mockImplementation((m: unknown) => void lines.push(String(m)));
    const app = await createApp(testConfig(), false);
    await app.init();
    const secret = 'سؤال-سري-فريد-الصوم';
    await request(app.getHttpServer())
      .post('/v1/retrieve')
      .send(body({ messages: [{ role: 'user', text: `${secret} الصوم` }] }))
      .expect(200);
    await request(app.getHttpServer())
      .post('/v1/retrieve')
      .send(body({ mode: 'bad', messages: [{ role: 'user', text: secret }] }))
      .expect(400);
    await app.close();
    spy.mockRestore();

    const all = lines.join('\n');
    expect(all).toContain('"event":"retrieve"');
    expect(all).toContain('"mode":"book_scope"');
    expect(all).not.toContain(secret);
    expect(all).not.toContain('فقرة اختبار'); // passage text
    expect(all).not.toContain('الصوم');
  });

  it('conversationId is ignored: same answers, no state kept', async () => {
    const app = await createApp(testConfig(), false);
    await app.init();
    const send = (conversationId?: string) =>
      request(app.getHttpServer())
        .post('/v1/retrieve')
        .send(body({ requestId: 'fixed-id', conversationId }));
    const a = (await send('conv-1')).body;
    const b = (await send('conv-2')).body;
    const c = (await send()).body;
    expect(b).toEqual(a);
    expect(c).toEqual(a);
    await app.close();
  });

  it('the backend has no database or storage dependency', () => {
    const pkg = JSON.parse(readFileSync(join(__dirname, '..', 'package.json'), 'utf8'));
    const deps = Object.keys({ ...pkg.dependencies, ...pkg.devDependencies }).join(' ');
    expect(deps).not.toMatch(/typeorm|prisma|sequelize|mongoose|\bpg\b|sqlite|redis|mysql|drizzle|knex/);
  });

  it('only the answer-report store writes to disk (chat code never does)', () => {
    const walk = (dir: string): string[] =>
      readdirSync(dir).flatMap((f) => {
        const p = join(dir, f);
        return statSync(p).isDirectory() ? walk(p) : [p];
      });
    const writers: string[] = [];
    for (const file of walk(join(__dirname, '..', 'src'))) {
      const src = readFileSync(file, 'utf8');
      if (/writeFile|appendFile|createWriteStream|\.mkdir|mkdir\(/.test(src)) writers.push(file.replace(/\\/g, '/'));
    }
    expect(writers).toHaveLength(1);
    expect(writers[0]).toMatch(/src\/reports\/report\.store\.ts$/);
  });
});

describe('production safety', () => {
  it('refuses to start in production with the FAKE corpus', async () => {
    await expect(createApp(testConfig({ nodeEnv: 'production' }), false, new FakeLlmProvider(), {
      attestation: new TestAttestation('x'),
    })).rejects.toThrow(CorpusError);
  });

  it('refuses to start in production without Play Integrity attestation', async () => {
    await expect(createApp(testConfig({ nodeEnv: 'production' }), false, new FakeLlmProvider())).rejects.toThrow(
      'ATTESTATION_MODE',
    );
  });

  it('the debug endpoint is 404 when disabled', async () => {
    const app = await createApp(testConfig({ retrieveEndpoint: false }), false);
    await app.init();
    await request(app.getHttpServer()).post('/v1/retrieve').send(body()).expect(404);
    await app.close();
  });
});
