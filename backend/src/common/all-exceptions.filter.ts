import { ArgumentsHost, Catch, ExceptionFilter, HttpException, Logger } from '@nestjs/common';
import type { Response } from 'express';

/** Fixed-shape errors; unexpected errors never leak details or input. */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('error');

  catch(exception: unknown, host: ArgumentsHost): void {
    const res = host.switchToHttp().getResponse<Response>();
    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const body = exception.getResponse();
      const inner = (body as { error?: unknown } | null)?.error;
      const isOurs = typeof inner === 'object' && inner !== null && 'code' in inner;
      const retry = (inner as { retryAfterSeconds?: unknown } | undefined)?.retryAfterSeconds;
      if (isOurs && typeof retry === 'number') res.setHeader('Retry-After', String(retry));
      res.status(status).json(
        isOurs
          ? body
          : {
              error: {
                code: status === 404 ? 'not_found' : status === 413 ? 'request_too_large' : status === 400 ? 'invalid_request' : 'http_error',
                message: 'Request failed.',
              },
            },
      );
      return;
    }
    // Body-parser errors (oversized or malformed JSON) are plain errors with a status.
    const bp = exception as { status?: unknown; type?: unknown } | null;
    if (typeof bp?.status === 'number' && typeof bp.type === 'string' && bp.status >= 400 && bp.status < 500) {
      const code = bp.status === 413 ? 'request_too_large' : 'invalid_request';
      res.status(bp.status).json({ error: { code, message: 'The request is not valid.' } });
      return;
    }
    // Log the error class only, never its message (it could contain input).
    this.logger.error(`unexpected error: ${exception instanceof Error ? exception.name : 'unknown'}`);
    res.status(500).json({ error: { code: 'internal_error', message: 'Internal error.' } });
  }
}
