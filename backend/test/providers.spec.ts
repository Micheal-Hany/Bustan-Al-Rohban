import type { INestApplication } from '@nestjs/common';
import { Logger } from '@nestjs/common';
import request from 'supertest';
import { ConfigError, configFromEnv, llmConfigFromEnv } from '../src/common/config';
import { createApp } from '../src/create-app';
import { FetchFn } from '../src/providers/http';
import { GeminiProvider } from '../src/providers/gemini.provider';
import { FakeLlmProvider } from '../src/providers/fake-llm';
import { LlmProvider, LlmRequest, ProviderError } from '../src/providers/llm.port';
import { OpenAiProvider } from '../src/providers/openai.provider';
import { PricingTable, estimateCost, loadPricing } from '../src/providers/pricing';
import { createProvider } from '../src/providers/provider.factory';
import { testConfig } from './helpers';

const KEY = 'sk-test-SECRET-KEY-123';
const req: LlmRequest = { system: 'SYS', prompt: 'PROMPT', question: 'q', passages: [] };
const reply = (status: number, body: unknown): Response =>
  new Response(typeof body === 'string' ? body : JSON.stringify(body), { status });

interface Adapter {
  name: string;
  make: (f: FetchFn, timeoutMs?: number) => LlmProvider;
  ok: (text: string, withUsage: boolean) => unknown;
  /** where the secret must be sent */
  keyHeader: string;
}
const adapters: Adapter[] = [
  {
    name: 'openai',
    make: (fetchFn, timeoutMs = 1000) =>
      new OpenAiProvider({ model: 'test-model', apiKey: KEY, timeoutMs, maxOutputTokens: 99, fetchFn }),
    ok: (text, u) => ({
      choices: [{ message: { content: text } }],
      ...(u ? { usage: { prompt_tokens: 11, completion_tokens: 7 } } : {}),
    }),
    keyHeader: 'authorization',
  },
  {
    name: 'gemini',
    make: (fetchFn, timeoutMs = 1000) =>
      new GeminiProvider({ model: 'test-model', apiKey: KEY, timeoutMs, maxOutputTokens: 99, fetchFn }),
    ok: (text, u) => ({
      candidates: [{ content: { parts: [{ text }] } }],
      ...(u ? { usageMetadata: { promptTokenCount: 11, candidatesTokenCount: 7 } } : {}),
    }),
    keyHeader: 'x-goog-api-key',
  },
];

describe.each(adapters)('$name adapter contract', (a) => {
  const fixed = (res: () => Response | Promise<Response>): FetchFn => (() => Promise.resolve(res())) as unknown as FetchFn;

  it('returns text, actual provider/model and usage', async () => {
    const r = await a.make(fixed(() => reply(200, a.ok('{"x":1}', true)))).generate(req);
    expect(r).toEqual({ text: '{"x":1}', provider: a.name, model: 'test-model', usage: { inputTokens: 11, outputTokens: 7 } });
  });
  it('reports usage as undefined when the provider omits it', async () => {
    const r = await a.make(fixed(() => reply(200, a.ok('{}', false)))).generate(req);
    expect(r.usage).toBeUndefined();
  });
  it('sends system and prompt, the key only in a header, never in the URL', async () => {
    const calls: { url: string; init: RequestInit }[] = [];
    const f = ((url: string, init: RequestInit) => {
      calls.push({ url, init });
      return Promise.resolve(reply(200, a.ok('{}', true)));
    }) as unknown as FetchFn;
    await a.make(f).generate(req);
    const headers = calls[0].init.headers as Record<string, string>;
    expect(calls[0].url).not.toContain(KEY);
    expect(headers[a.keyHeader]).toContain(KEY);
    expect(String(calls[0].init.body)).not.toContain(KEY);
    expect(String(calls[0].init.body)).toContain('SYS');
    expect(String(calls[0].init.body)).toContain('PROMPT');
    expect(calls[0].init.method).toBe('POST');
  });
  it.each([
    [401, 'auth'], [403, 'auth'], [429, 'rate_limited'], [408, 'timeout'], [504, 'timeout'],
    [500, 'server'], [503, 'server'], [400, 'bad_request'],
  ])('maps HTTP %i to %s without leaking the body', async (status, kind) => {
    const p = a.make(fixed(() => reply(status, `leak ${KEY} PROMPT`)));
    const err = await p.generate(req).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(ProviderError);
    expect((err as ProviderError).kind).toBe(kind);
    expect((err as Error).message).not.toContain(KEY);
    expect((err as Error).message).not.toContain('PROMPT');
  });
  it('maps network failure to network', async () => {
    const p = a.make((() => Promise.reject(new Error(`boom ${KEY}`))) as unknown as FetchFn);
    const err = (await p.generate(req).catch((e: unknown) => e)) as ProviderError;
    expect(err.kind).toBe('network');
    expect(err.message).not.toContain(KEY);
  });
  it('times out when the provider hangs', async () => {
    const hang = ((_u: string, init: RequestInit) =>
      new Promise((_res, rej) => {
        init.signal?.addEventListener('abort', () => rej(new Error('aborted')));
      })) as unknown as FetchFn;
    const err = (await a.make(hang, 30).generate(req).catch((e: unknown) => e)) as ProviderError;
    expect(err.kind).toBe('timeout');
  });
  it.each([
    ['non-JSON body', () => reply(200, 'not json')],
    ['empty content', () => reply(200, a.ok('   ', true))],
    ['no candidates/choices', () => reply(200, {})],
  ])('rejects %s as bad_response', async (_n, res) => {
    const err = (await a.make(fixed(res)).generate(req).catch((e: unknown) => e)) as ProviderError;
    expect(err.kind).toBe('bad_response');
  });
});

describe('provider selection by configuration', () => {
  it('switches adapter from env only', () => {
    const f = ((): Promise<Response> => Promise.resolve(reply(200, {}))) as unknown as FetchFn;
    const make = (env: NodeJS.ProcessEnv) => createProvider(llmConfigFromEnv(env), f);
    expect(make({})).toBeInstanceOf(FakeLlmProvider);
    expect(make({ LLM_PROVIDER: 'openai', LLM_MODEL: 'm', OPENAI_API_KEY: 'k' })).toBeInstanceOf(OpenAiProvider);
    expect(make({ LLM_PROVIDER: 'gemini', LLM_MODEL: 'm', GEMINI_API_KEY: 'k' })).toBeInstanceOf(GeminiProvider);
  });
  it('fails fast on missing key, model or unknown provider', () => {
    expect(() => llmConfigFromEnv({ LLM_PROVIDER: 'openai', LLM_MODEL: 'm' })).toThrow(ConfigError);
    expect(() => llmConfigFromEnv({ LLM_PROVIDER: 'gemini', GEMINI_API_KEY: 'k' })).toThrow(ConfigError);
    expect(() => llmConfigFromEnv({ LLM_PROVIDER: 'other' })).toThrow(ConfigError);
    expect(() => llmConfigFromEnv({ LLM_TIMEOUT_MS: '0' })).toThrow(ConfigError);
  });
  it('uses the key of the chosen provider only', () => {
    const c = llmConfigFromEnv({ LLM_PROVIDER: 'gemini', LLM_MODEL: 'm', OPENAI_API_KEY: 'o', GEMINI_API_KEY: 'g' });
    expect(c.apiKey).toBe('g');
    expect(configFromEnv({ LLM_PROVIDER: 'fake' }).llm.apiKey).toBeUndefined();
  });
});

describe('cost estimation', () => {
  const table: PricingTable = loadPricing(testConfig().pricingFile);
  it('computes USD from tokens and per-million prices', () => {
    expect(estimateCost(table, 'openai', 'test-model', { inputTokens: 1_000_000, outputTokens: 500_000 })).toEqual({
      status: 'estimated', amountUsd: 6, pricingVersion: 'test-1',
    });
    expect(estimateCost(table, 'gemini', 'test-model', { inputTokens: 1234, outputTokens: 567 }).amountUsd).toBeCloseTo(0.003502, 8);
  });
  it('is unavailable when usage is missing or partial', () => {
    expect(estimateCost(table, 'openai', 'test-model', undefined)).toMatchObject({ status: 'unavailable', amountUsd: null, reason: 'usage_missing' });
    expect(estimateCost(table, 'openai', 'test-model', { inputTokens: 5 })).toMatchObject({ reason: 'usage_missing' });
  });
  it('is unavailable (never guessed) for an unpriced model', () => {
    expect(estimateCost(table, 'openai', 'other', { inputTokens: 1, outputTokens: 1 })).toMatchObject({ status: 'unavailable', reason: 'no_pricing' });
  });
  it('carries the pricing version of the table used', () => {
    expect(estimateCost({ ...table, version: 'v9' }, 'openai', 'test-model', { inputTokens: 0, outputTokens: 0 }).pricingVersion).toBe('v9');
  });
  it('the shipped pricing file is valid and unpriced until the owner fills it', () => {
    const shipped = loadPricing('config/pricing.json');
    expect(shipped.models).toEqual({});
  });
});

describe('POST /v1/chat with a mocked real adapter', () => {
  let app: INestApplication;
  let calls = 0;
  const logs: string[] = [];
  const q = 'ماذا يقول الكتاب عن الصوم والانقطاع عن الطعام؟';

  beforeAll(async () => {
    jest.spyOn(Logger.prototype, 'log').mockImplementation((m: unknown) => void logs.push(String(m)));
    const f = ((_u: string, init: RequestInit) => {
      calls++;
      const prompt = JSON.parse(String(init.body)).messages[1].content as string;
      const id = /<passage id="([^"]+)"/.exec(prompt)?.[1] ?? 'none';
      const text = JSON.stringify({ status: 'answered', blocks: [{ type: 'paraphrase', text: 'تلخيص', citations: [id] }] });
      return Promise.resolve(reply(200, { choices: [{ message: { content: text } }], usage: { prompt_tokens: 1000, completion_tokens: 200 } }));
    }) as unknown as FetchFn;
    const cfg = testConfig({ llm: { provider: 'openai', model: 'test-model', apiKey: KEY, timeoutMs: 1000, maxOutputTokens: 500 } });
    app = await createApp(cfg, false, createProvider(cfg.llm, f));
    await app.init();
  });
  afterAll(() => app.close());

  it('records actual provider/model, usage and estimated cost; no key or text leaks', async () => {
    const res = await request(app.getHttpServer())
      .post('/v1/chat')
      .send({ mode: 'book_scope', scope: {}, messages: [{ role: 'user', text: q }] })
      .expect(200);
    expect(calls).toBe(1);
    expect(res.body.meta).toMatchObject({
      provider: 'openai', model: 'test-model', attempts: 1,
      usage: { inputTokens: 1000, outputTokens: 200 },
      cost: { status: 'estimated', pricingVersion: 'test-1' },
    });
    expect(res.body.meta.cost.amountUsd).toBeCloseTo(0.0036, 8);
    const line = logs.find((l) => l.includes('"event":"chat"')) as string;
    expect(JSON.parse(line)).toMatchObject({ provider: 'openai', model: 'test-model', inputTokens: 1000, costStatus: 'estimated', pricingVersion: 'test-1' });
    const everything = JSON.stringify(res.body) + logs.join('\n');
    expect(everything).not.toContain(KEY);
    expect(everything).not.toContain('الصوم والانقطاع');
  });

  it.each([
    [429, 503, 'provider_busy'], [504, 504, 'provider_timeout'], [401, 502, 'provider_error'], [500, 502, 'provider_error'],
  ])('maps provider HTTP %i to %i %s', async (upstream, status, code) => {
    const cfg = testConfig({ llm: { provider: 'gemini', model: 'test-model', apiKey: KEY, timeoutMs: 1000, maxOutputTokens: 5 } });
    const a = await createApp(cfg, false, createProvider(cfg.llm, (() => Promise.resolve(reply(upstream, `x ${KEY}`))) as unknown as FetchFn));
    await a.init();
    const res = await request(a.getHttpServer())
      .post('/v1/chat')
      .send({ mode: 'book_scope', scope: {}, messages: [{ role: 'user', text: q }] })
      .expect(status);
    expect(res.body.error.code).toBe(code);
    expect(JSON.stringify(res.body)).not.toContain(KEY);
    await a.close();
  });
});
