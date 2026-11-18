import { HttpException } from '@nestjs/common';

/**
 * An error with a stable machine code. The message is fixed text: it never
 * contains user input (questions are not echoed back or logged).
 */
export class AppError extends HttpException {
  constructor(
    status: number,
    readonly code: string,
    message: string,
    /** Extra machine-readable, non-sensitive fields (e.g. retryAfterSeconds). */
    extra: Record<string, number | string | boolean> = {},
  ) {
    super({ error: { code, message, ...extra } }, status);
  }
}

export const badRequest = (code: string, message: string) => new AppError(400, code, message);
export const tooManyRequests = (retryAfterSeconds: number) =>
  new AppError(429, 'rate_limited', 'Too many requests. Try again later.', { retryAfterSeconds });
/** Friendly "temporarily unavailable" (spend cap / kill switch / busy). */
export const temporarilyUnavailable = (code = 'temporarily_unavailable') =>
  new AppError(503, code, 'The assistant is temporarily unavailable. Please try again later.');
