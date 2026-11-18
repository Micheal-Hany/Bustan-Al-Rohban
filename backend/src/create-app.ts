import { NestFactory } from '@nestjs/core';
import type { INestApplication, LogLevel } from '@nestjs/common';
import { AllExceptionsFilter } from './common/all-exceptions.filter';
import { AppConfig } from './common/config';
import { AppDeps, AppModule } from './app.module';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { LlmProvider } from './providers/llm.port';

/** Builds the app; shared by main.ts and the tests. */
export async function createApp(
  config: AppConfig,
  logger: LogLevel[] | false = ['log', 'warn', 'error'],
  llm?: LlmProvider,
  deps?: AppDeps,
): Promise<INestApplication> {
  // The fake model is for development and tests only.
  if (config.nodeEnv === 'production' && !llm && config.llm.provider === 'fake') {
    throw new Error('Production needs LLM_PROVIDER=openai or gemini.');
  }
  if (config.nodeEnv === 'production' && config.protection.attestation.mode !== 'play_integrity' && !deps?.attestation) {
    throw new Error('Production needs ATTESTATION_MODE=play_integrity.');
  }
  const app = await NestFactory.create<NestExpressApplication>(AppModule.register(config, llm, deps), {
    logger,
    abortOnError: false,
  });
  app.set('trust proxy', config.trustProxy);
  app.useBodyParser('json', { limit: '64kb' });
  app.useGlobalFilters(new AllExceptionsFilter());
  return app;
}
