import { Body, Controller, HttpCode, Inject, NotFoundException, Post } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { APP_CONFIG, AppConfig } from '../common/config';
import { RequestLogger } from '../common/request-logger';
import { parseRetrievalRequest } from './retrieval.dto';
import { RetrievalService } from './retrieval.service';

/**
 * Debug endpoint that exposes the retrieval step on its own (the real chat
 * endpoint arrives in Task 10b). Disabled in production.
 */
@Controller('v1')
export class RetrievalController {
  constructor(
    @Inject(RetrievalService) private readonly retrieval: RetrievalService,
    @Inject(RequestLogger) private readonly logger: RequestLogger,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  @Post('retrieve')
  @HttpCode(200)
  retrieve(@Body() body: unknown) {
    if (!this.config.retrieveEndpoint) throw new NotFoundException();
    const started = Date.now();
    const req = parseRetrievalRequest(body);
    const requestId = req.requestId ?? randomUUID();
    const result = this.retrieval.retrieve(req);
    this.logger.log({
      event: 'retrieve',
      requestId,
      mode: req.mode,
      saintId: req.scope.saintId,
      sectionId: req.scope.sectionId,
      status: result.status,
      reason: result.status === 'refused' ? result.reason : undefined,
      hits: result.status === 'ok' ? result.passages.length : 0,
      ms: Date.now() - started,
    });
    return { requestId, ...result };
  }
}
