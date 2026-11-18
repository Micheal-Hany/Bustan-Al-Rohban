import { NestFactory } from '@nestjs/core';
import type { INestApplication, LogLevel } from '@nestjs/common';
import { AllExceptionsFilter } from './common/all-exceptions.filter';
import { AppConfig } from './common/config';
import { AppModule } from './app.module';

/** Builds the app; shared by main.ts and the tests. */
export async function createApp(
  config: AppConfig,
  logger: LogLevel[] | false = ['log', 'warn', 'error'],
): Promise<INestApplication> {
  const app = await NestFactory.create(AppModule.register(config), { logger, abortOnError: false });
  app.useGlobalFilters(new AllExceptionsFilter());
  return app;
}
