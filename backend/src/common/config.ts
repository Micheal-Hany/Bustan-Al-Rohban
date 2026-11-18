export interface AppConfig {
  corpusDir: string;
  nodeEnv: string;
  /** Debug endpoint POST /v1/retrieve. Always off in production. */
  retrieveEndpoint: boolean;
  port: number;
  llm: LlmConfig;
  /** Versioned pricing file (config/pricing.json). */
  pricingFile: string;
}

export type LlmProviderName = 'fake' | 'openai' | 'gemini';

/** Provider and model are chosen here (environment), never in code. */
export interface LlmConfig {
  provider: LlmProviderName;
  model?: string;
  /** Secret. Only ever used in a request header; never logged or returned. */
  apiKey?: string;
  timeoutMs: number;
  maxOutputTokens: number;
}

export class ConfigError extends Error {}

export const APP_CONFIG = 'APP_CONFIG';

export function configFromEnv(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const nodeEnv = env.NODE_ENV ?? 'development';
  return {
    corpusDir: env.CORPUS_DIR ?? '../assets/content',
    nodeEnv,
    retrieveEndpoint: nodeEnv !== 'production' && env.ENABLE_RETRIEVE_ENDPOINT !== 'false',
    port: Number(env.PORT ?? 3000),
    pricingFile: env.PRICING_FILE ?? 'config/pricing.json',
    llm: llmConfigFromEnv(env),
  };
}

export function llmConfigFromEnv(env: NodeJS.ProcessEnv): LlmConfig {
  const provider = (env.LLM_PROVIDER ?? 'fake') as LlmProviderName;
  if (!['fake', 'openai', 'gemini'].includes(provider)) {
    throw new ConfigError('LLM_PROVIDER must be fake, openai or gemini.');
  }
  const apiKey = provider === 'openai' ? env.OPENAI_API_KEY : provider === 'gemini' ? env.GEMINI_API_KEY : undefined;
  const timeoutMs = Number(env.LLM_TIMEOUT_MS ?? 30000);
  const maxOutputTokens = Number(env.LLM_MAX_OUTPUT_TOKENS ?? 1200);
  if (!Number.isFinite(timeoutMs) || timeoutMs <= 0 || !Number.isFinite(maxOutputTokens) || maxOutputTokens <= 0) {
    throw new ConfigError('LLM_TIMEOUT_MS and LLM_MAX_OUTPUT_TOKENS must be positive numbers.');
  }
  if (provider !== 'fake') {
    if (!env.LLM_MODEL) throw new ConfigError('LLM_MODEL is required for a real provider.');
    if (!apiKey) throw new ConfigError(`The API key for ${provider} is not set.`);
  }
  return { provider, model: env.LLM_MODEL, apiKey, timeoutMs, maxOutputTokens };
}
