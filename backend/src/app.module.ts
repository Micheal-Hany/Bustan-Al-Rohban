import { DynamicModule, Module } from '@nestjs/common';
import { APP_CONFIG, AppConfig } from './common/config';
import { RequestLogger } from './common/request-logger';
import { HealthController } from './health/health.controller';
import type { AttestationVerifier } from './protection/attestation';
import { ReportsController } from './reports/reports.controller';
import { ProtectionService } from './protection/protection.service';
import { SpendGuard } from './protection/spend-guard';
import { ATTESTATION, createAttestationVerifier } from './protection/attestation';
import { ChatController } from './chat/chat.controller';
import { ChatService, PRICING } from './chat/chat.service';
import { loadPricing } from './providers/pricing';
import { createProvider } from './providers/provider.factory';
import { LLM_PROVIDER, LlmProvider } from './providers/llm.port';
import { RetrievalController } from './retrieval/retrieval.controller';
import { RetrievalService } from './retrieval/retrieval.service';
import { CorpusService } from './sources/corpus.service';

/** Test seams (never set in production code). */
export interface AppDeps {
  attestation?: AttestationVerifier;
}

@Module({})
export class AppModule {
  static register(config: AppConfig, llm?: LlmProvider, deps: AppDeps = {}): DynamicModule {
    return {
      module: AppModule,
      controllers: [HealthController, RetrievalController, ChatController, ReportsController],
      providers: [
        { provide: APP_CONFIG, useValue: config },
        CorpusService,
        RetrievalService,
        ChatService,
        ProtectionService,
        { provide: SpendGuard, useValue: new SpendGuard(config.protection) },
        { provide: ATTESTATION, useValue: deps.attestation ?? createAttestationVerifier(config.protection.attestation) },
        { provide: LLM_PROVIDER, useValue: llm ?? createProvider(config.llm) },
        { provide: PRICING, useValue: loadPricing(config.pricingFile) },
        RequestLogger,
      ],
    };
  }
}
