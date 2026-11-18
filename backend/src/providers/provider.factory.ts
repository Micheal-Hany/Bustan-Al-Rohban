import { ConfigError, LlmConfig } from '../common/config';
import { FakeLlmProvider } from './fake-llm';
import { GeminiProvider } from './gemini.provider';
import { FetchFn } from './http';
import { LlmProvider } from './llm.port';
import { OpenAiProvider } from './openai.provider';

/** Chooses the adapter from configuration only (no code change to switch). */
export function createProvider(cfg: LlmConfig, fetchFn?: FetchFn): LlmProvider {
  if (cfg.provider === 'fake') return new FakeLlmProvider();
  if (!cfg.model || !cfg.apiKey) throw new ConfigError('Model and API key are required.');
  const o = { model: cfg.model, apiKey: cfg.apiKey, timeoutMs: cfg.timeoutMs, maxOutputTokens: cfg.maxOutputTokens, fetchFn };
  return cfg.provider === 'openai' ? new OpenAiProvider(o) : new GeminiProvider(o);
}
