export interface AppConfig {
  corpusDir: string;
  nodeEnv: string;
  /** Debug endpoint POST /v1/retrieve. Always off in production. */
  retrieveEndpoint: boolean;
  port: number;
}

export const APP_CONFIG = 'APP_CONFIG';

export function configFromEnv(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const nodeEnv = env.NODE_ENV ?? 'development';
  return {
    corpusDir: env.CORPUS_DIR ?? '../assets/content',
    nodeEnv,
    retrieveEndpoint: nodeEnv !== 'production' && env.ENABLE_RETRIEVE_ENDPOINT !== 'false',
    port: Number(env.PORT ?? 3000),
  };
}
