import 'reflect-metadata';
import { configFromEnv } from './common/config';
import { createApp } from './create-app';

async function bootstrap(): Promise<void> {
  const config = configFromEnv();
  const app = await createApp(config);
  await app.listen(config.port);
}

bootstrap().catch((e: unknown) => {
  // Print only the error class/message of startup problems (no user input here).
  console.error(e instanceof Error ? e.message : 'startup failed');
  process.exit(1);
});
