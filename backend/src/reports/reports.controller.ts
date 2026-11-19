import { Body, Controller, HttpCode, Inject, Post, Req } from '@nestjs/common';
import type { Request } from 'express';
import { randomUUID } from 'node:crypto';
import { z } from 'zod';
import { AppError, badRequest } from '../common/app-error';
import { RequestLogger } from '../common/request-logger';
import { ProtectionService } from '../protection/protection.service';
import { REPORT_STORE, ReportStore } from './report.store';

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
 * Answer reports (SPEC 7.8). Stores ONLY the reported answer, the question
 * that produced it, cited paragraph ids, content version, provider/model, the
 * reason and the optional note: no history, installation id, IP or token.
 * Report text is never logged (the log has the id, reason category, counts).
 * Without a configured store the endpoint answers 503 and keeps nothing.
 */
@Controller('v1')
export class ReportsController {
  constructor(
    @Inject(RequestLogger) private readonly logger: RequestLogger,
    @Inject(ProtectionService) private readonly protection: ProtectionService,
    @Inject(REPORT_STORE) private readonly store: ReportStore | null,
  ) {}

  @Post('reports')
  @HttpCode(202)
  async report(@Body() body: unknown, @Req() http: Request) {
    this.protection.admitIp(http.ip);
    const r = reportSchema.safeParse(body);
    if (!r.success) throw badRequest('invalid_request', 'The request is not valid.');
    await this.protection.admitClient(r.data);
    if (!this.store) {
      throw new AppError(503, 'reports_unavailable', 'Reports are not available right now.');
    }
    const d = r.data;
    const reportId = randomUUID();
    await this.store.add({
      id: reportId,
      receivedAt: new Date().toISOString(),
      reason: d.reason,
      ...(d.note ? { note: d.note } : {}),
      answerText: d.answerText,
      question: d.question,
      citedParagraphIds: d.citedParagraphIds,
      contentVersion: d.contentVersion,
      provider: d.provider,
      model: d.model,
    });
    this.logger.log({ event: 'report', requestId: reportId, status: 'stored', reason: d.reason, hits: d.citedParagraphIds.length });
    return { reportId, stored: true };
  }
}
