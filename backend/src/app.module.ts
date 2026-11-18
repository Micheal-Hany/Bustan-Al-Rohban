import { DynamicModule, Module } from '@nestjs/common';
import { APP_CONFIG, AppConfig } from './common/config';
import { RequestLogger } from './common/request-logger';
import { HealthController } from './health/health.controller';
import { RetrievalController } from './retrieval/retrieval.controller';
import { RetrievalService } from './retrieval/retrieval.service';
import { CorpusService } from './sources/corpus.service';

@Module({})
export class AppModule {
  static register(config: AppConfig): DynamicModule {
    return {
      module: AppModule,
      controllers: [HealthController, RetrievalController],
      providers: [
        { provide: APP_CONFIG, useValue: config },
        CorpusService,
        RetrievalService,
        RequestLogger,
      ],
    };
  }
}
