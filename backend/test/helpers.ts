import { join } from 'node:path';
import { AppConfig } from '../src/common/config';
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
  ...over,
});

export const fixtureCorpus = () => loadCorpus(FIXTURE_DIR);
