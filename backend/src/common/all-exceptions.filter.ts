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
      res.status(status).json(
        isOurs
          ? body
          : { error: { code: status === 404 ? 'not_found' : 'http_error', message: 'Request failed.' } },
      );
      return;
    }
    // Log the error class only, never its message (it could contain input).
    this.logger.error(`unexpected error: ${exception instanceof Error ? exception.name : 'unknown'}`);
    res.status(500).json({ error: { code: 'internal_error', message: 'Internal error.' } });
  }
}
