import { join } from 'node:path';
import { AppConfig, ProtectionConfig } from '../src/common/config';
import { loadCorpus } from '../src/sources/corpus.loader';

export const FIXTURE_DIR = join(__dirname, 'fixtures', 'corpus');
/** The FAKE corpus the Flutter app ships. */
export const APP_CONTENT_DIR = join(__dirname, '..', '..', 'assets', 'content');

export const testConfig = (over: Partial<AppConfig> = {}): AppConfig => ({
  corpusDir: FIXTURE_DIR,
  nodeEnv: 'test',
  retrieveEndpoint: true,
  port: 0,
  pricingFile: join(__dirname, 'fixtures', 'pricing.json'),
  llm: { provider: 'fake', timeoutMs: 1000, maxOutputTokens: 500 },
  trustProxy: 0,
  protection: testProtection(),
  ...over,
});

export const fixtureCorpus = () => loadCorpus(FIXTURE_DIR);

export const testProtection = (over: Partial<ProtectionConfig> = {}): ProtectionConfig => ({
  ipLimit: { max: 1000, windowSeconds: 3600 },
  installationLimit: { max: 1000, windowSeconds: 3600 },
  attestation: { mode: 'off', certDigests: [], maxTokenAgeSeconds: 300 },
  dailyCapUsd: 1000,
  unknownCostUsd: 0.02,
  killSwitch: false,
  maxConcurrentModelCalls: 8,
  ...over,
});
