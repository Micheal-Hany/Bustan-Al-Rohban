import { Injectable, Logger } from '@nestjs/common';

/**
 * Operational log entry. It deliberately has no field for question text,
 * messages, passages or prompts: only ids, scope, outcome and timing.
 */
export interface LogEntry {
  event: string;
  requestId: string;
  mode?: string;
  saintId?: string;
  sectionId?: string;
  status?: string;
  reason?: string;
  hits?: number;
  ms?: number;
  errorCode?: string;
  /** Model call facts (no text): which model, tokens, estimated cost. */
  provider?: string;
  model?: string;
  inputTokens?: number;
  outputTokens?: number;
  costUsd?: number | null;
  costStatus?: string;
  pricingVersion?: string;
}

@Injectable()
export class RequestLogger {
  private readonly logger = new Logger('request');

  log(entry: LogEntry): void {
    this.logger.log(JSON.stringify(entry));
  }
}
