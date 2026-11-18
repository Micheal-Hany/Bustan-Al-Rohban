import { DynamicModule, Module } from '@nestjs/common';
import { APP_CONFIG, AppConfig } from './common/config';
import { RequestLogger } from './common/request-logger';
import { HealthController } from './health/health.controller';
import { ChatController } from './chat/chat.controller';
import { ChatService } from './chat/chat.service';
import { FakeLlmProvider } from './providers/fake-llm';
import { LLM_PROVIDER, LlmProvider } from './providers/llm.port';
import { RetrievalController } from './retrieval/retrieval.controller';
import { RetrievalService } from './retrieval/retrieval.service';
import { CorpusService } from './sources/corpus.service';

@Module({})
export class AppModule {
  static register(config: AppConfig, llm?: LlmProvider): DynamicModule {
    return {
      module: AppModule,
      controllers: [HealthController, RetrievalController, ChatController],
      providers: [
        { provide: APP_CONFIG, useValue: config },
        CorpusService,
        RetrievalService,
        ChatService,
        { provide: LLM_PROVIDER, useValue: llm ?? new FakeLlmProvider() },
        RequestLogger,
      ],
    };
  }
}
