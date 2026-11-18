import { Body, Controller, HttpCode, Inject, Post, Req } from '@nestjs/common';
import type { Request } from 'express';
import { randomUUID } from 'node:crypto';
import { z } from 'zod';
import { badRequest } from '../common/app-error';
import { RequestLogger } from '../common/request-logger';
import { ProtectionService } from '../protection/protection.service';

const reportSchema = z
  .object({
    requestId: z.string().regex(/^[A-Za-z0-9_-]{1,64}$/).optional(),
    installationId: z.string().regex(/^[A-Za-z0-9_-]{16,64}$/).optional(),
    attestationToken: z.string().min(1).max(8192).optional(),
    reason: z.enum(['wrong_or_invented', 'not_from_book', 'offensive_or_unsafe', 'doctrinal_concern', 'other']),
    note: z.string().trim().max(500).optional(),
    /** SPEC 7.8: only these fields, never the conversation history. */
    answerText: z.string().min(1).max(6000),
    question: z.string().min(1).max(2000),
    citedParagraphIds: z.array(z.string().regex(/^[A-Za-z0-9_-]{1,100}$/)).max(20),
    contentVersion: z.number().int().min(0),
    provider: z.string().min(1).max(40),
    model: z.string().min(1).max(100),
  })
  .strict();

/**
 * STUB (Task 10d): validates and acknowledges an answer report but stores
 * nothing yet. Persistence (owner-review store, no history) is Task 12a.
 * Report text is never logged: the log has only the id, the reason category
 * and counts.
 */
@Controller('v1')
export class ReportsController {
  constructor(
    @Inject(RequestLogger) private readonly logger: RequestLogger,
    @Inject(ProtectionService) private readonly protection: ProtectionService,
  ) {}

  @Post('reports')
  @HttpCode(202)
  async report(@Body() body: unknown, @Req() http: Request) {
    this.protection.admitIp(http.ip);
    const r = reportSchema.safeParse(body);
    if (!r.success) throw badRequest('invalid_request', 'The request is not valid.');
    await this.protection.admitClient(r.data);
    const reportId = randomUUID();
    this.logger.log({ event: 'report', requestId: reportId, status: 'accepted_not_stored', reason: r.data.reason, hits: r.data.citedParagraphIds.length });
    return { reportId, stored: false };
  }
}
