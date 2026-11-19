export interface AppConfig {
  corpusDir: string;
  nodeEnv: string;
  /** Debug endpoint POST /v1/retrieve. Always off in production. */
  retrieveEndpoint: boolean;
  port: number;
  llm: LlmConfig;
  /** Versioned pricing file (config/pricing.json). */
  pricingFile: string;
  protection: ProtectionConfig;
  /** Express "trust proxy" hops so the client IP is read correctly behind a proxy. */
  trustProxy: number;
  /** Append-only file for answer reports. Unset: report endpoint answers 503. */
  reportsFile?: string;
}

export type AttestationMode = 'off' | 'test' | 'play_integrity';

export interface RateLimitConfig {
  max: number;
  windowSeconds: number;
}

/**
 * Abuse protection and spend controls (SPEC 7.5). The numeric defaults are
 * PROPOSED values: SPEC section 19 decision 5 (budget, limits, cap) is open
 * and the owner sets the real ones.
 */
export interface ProtectionConfig {
  ipLimit: RateLimitConfig;
  installationLimit: RateLimitConfig;
  attestation: {
    mode: AttestationMode;
    /** mode=test: the token the backend accepts (dev/CI only). */
    testToken?: string;
    /** mode=play_integrity */
    packageName?: string;
    serviceAccountFile?: string;
    /** Optional allow-list of signing-certificate SHA-256 digests (base64). */
    certDigests: string[];
    maxTokenAgeSeconds: number;
  };
  dailyCapUsd: number;
  /** Charged to the daily total when a call's real cost is unknown. */
  unknownCostUsd: number;
  killSwitch: boolean;
  maxConcurrentModelCalls: number;
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
    trustProxy: Number(env.TRUST_PROXY_HOPS ?? 0),
    reportsFile: env.REPORTS_FILE || undefined,
    protection: protectionFromEnv(env),
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

const positive = (name: string, raw: string | undefined, fallback: number): number => {
  const n = Number(raw ?? fallback);
  if (!Number.isFinite(n) || n <= 0) throw new ConfigError(`${name} must be a positive number.`);
  return n;
};

export function protectionFromEnv(env: NodeJS.ProcessEnv): ProtectionConfig {
  const mode = (env.ATTESTATION_MODE ?? 'off') as AttestationMode;
  if (!['off', 'test', 'play_integrity'].includes(mode)) {
    throw new ConfigError('ATTESTATION_MODE must be off, test or play_integrity.');
  }
  if (mode === 'test' && !env.ATTESTATION_TEST_TOKEN) throw new ConfigError('ATTESTATION_TEST_TOKEN is required in test mode.');
  if (mode === 'play_integrity' && (!env.PLAY_PACKAGE_NAME || !env.GOOGLE_SERVICE_ACCOUNT_FILE)) {
    throw new ConfigError('PLAY_PACKAGE_NAME and GOOGLE_SERVICE_ACCOUNT_FILE are required for play_integrity.');
  }
  return {
    ipLimit: { max: positive('RATE_IP_MAX', env.RATE_IP_MAX, 60), windowSeconds: positive('RATE_IP_WINDOW_SECONDS', env.RATE_IP_WINDOW_SECONDS, 3600) },
    installationLimit: {
      max: positive('RATE_INSTALLATION_MAX', env.RATE_INSTALLATION_MAX, 20),
      windowSeconds: positive('RATE_INSTALLATION_WINDOW_SECONDS', env.RATE_INSTALLATION_WINDOW_SECONDS, 3600),
    },
    attestation: {
      mode,
      testToken: env.ATTESTATION_TEST_TOKEN,
      packageName: env.PLAY_PACKAGE_NAME,
      serviceAccountFile: env.GOOGLE_SERVICE_ACCOUNT_FILE,
      certDigests: (env.PLAY_CERT_SHA256 ?? '').split(',').map((x) => x.trim()).filter(Boolean),
      maxTokenAgeSeconds: positive('ATTESTATION_MAX_AGE_SECONDS', env.ATTESTATION_MAX_AGE_SECONDS, 300),
    },
    dailyCapUsd: positive('DAILY_SPEND_CAP_USD', env.DAILY_SPEND_CAP_USD, 5),
    unknownCostUsd: positive('UNKNOWN_COST_USD', env.UNKNOWN_COST_USD, 0.02),
    killSwitch: env.AI_KILL_SWITCH === 'true',
    maxConcurrentModelCalls: positive('MAX_CONCURRENT_MODEL_CALLS', env.MAX_CONCURRENT_MODEL_CALLS, 8),
  };
}
