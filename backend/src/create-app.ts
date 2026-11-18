import { NestFactory } from '@nestjs/core';
import type { INestApplication, LogLevel } from '@nestjs/common';
import { AllExceptionsFilter } from './common/all-exceptions.filter';
import { AppConfig } from './common/config';
import { AppModule } from './app.module';
import { LlmProvider } from './providers/llm.port';

/** Builds the app; shared by main.ts and the tests. */
export async function createApp(
  config: AppConfig,
  logger: LogLevel[] | false = ['log', 'warn', 'error'],
  llm?: LlmProvider,
): Promise<INestApplication> {
  // The fake model is for development and tests only.
  if (config.nodeEnv === 'production' && !llm && config.llm.provider === 'fake') {
    throw new Error('Production needs LLM_PROVIDER=openai or gemini.');
  }
  const app = await NestFactory.create(AppModule.register(config, llm), { logger, abortOnError: false });
  app.useGlobalFilters(new AllExceptionsFilter());
  return app;
}
