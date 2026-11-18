import { Body, Controller, HttpCode, Inject, Post, Req } from '@nestjs/common';
import type { Request } from 'express';
import { randomUUID } from 'node:crypto';
import { RequestLogger } from '../common/request-logger';
import { parseRetrievalRequest } from '../retrieval/retrieval.dto';
import { ProtectionService } from '../protection/protection.service';
import { ChatService } from './chat.service';

/** POST /v1/chat: stateless, non-streaming (SPEC 12.3). */
@Controller('v1')
export class ChatController {
  constructor(
    @Inject(ChatService) private readonly chat: ChatService,
    @Inject(RequestLogger) private readonly logger: RequestLogger,
    @Inject(ProtectionService) private readonly protection: ProtectionService,
  ) {}

  @Post('chat')
  @HttpCode(200)
  async post(@Body() body: unknown, @Req() http: Request) {
    const started = Date.now();
    this.protection.admitIp(http.ip);
    const req = parseRetrievalRequest(body);
    await this.protection.admitClient(req);
    const requestId = req.requestId ?? randomUUID();
    const result = await this.chat.answer(req);
    this.logger.log({
      event: 'chat',
      requestId,
      mode: req.mode,
      saintId: req.scope.saintId,
      sectionId: req.scope.sectionId,
      status: result.outcome,
      reason:
        result.validationCodes?.join(',') ??
        (result.response.status === 'refused' ? result.response.reason : undefined),
      hits: result.attempts,
      provider: result.model?.provider,
      model: result.model?.model,
      inputTokens: result.model?.usage?.inputTokens,
      outputTokens: result.model?.usage?.outputTokens,
      costUsd: result.model?.cost.amountUsd,
      costStatus: result.model?.cost.status,
      pricingVersion: result.model?.cost.pricingVersion,
      ms: Date.now() - started,
    });
    return { requestId, ...result.response };
  }
}
