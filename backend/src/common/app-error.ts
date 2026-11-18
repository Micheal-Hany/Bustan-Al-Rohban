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
  ) {
    super({ error: { code, message } }, status);
  }
}

export const badRequest = (code: string, message: string) => new AppError(400, code, message);
