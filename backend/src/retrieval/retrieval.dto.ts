import { z } from 'zod';
import { badRequest } from '../common/app-error';
import { RetrievalRequest } from './retrieval.types';

export const MAX_MESSAGES = 20;
export const MAX_MESSAGE_CHARS = 2000;
export const MAX_TOTAL_CHARS = 8000;

const id = z.string().regex(/^[A-Za-z0-9_-]{1,100}$/);

const requestSchema = z
  .object({
    requestId: z.string().regex(/^[A-Za-z0-9_-]{1,64}$/).optional(),
    /** Correlation only; the backend never uses it to load or store history. */
    conversationId: z.string().regex(/^[A-Za-z0-9_-]{1,64}$/).optional(),
    /** Client-generated, stable per install. Rate-limit key only; NOT authentication. */
    installationId: z.string().regex(/^[A-Za-z0-9_-]{16,64}$/).optional(),
    /** Play Integrity token (SPEC 12.3). */
    attestationToken: z.string().min(1).max(8192).optional(),
    mode: z.enum(['saint_scope', 'book_scope']),
    scope: z
      .object({ bookId: id.optional(), saintId: id.optional(), sectionId: id.optional() })
      .strict()
      .default({}),
    messages: z
      .array(
        z
          .object({
            role: z.enum(['user', 'assistant']),
            text: z.string().trim().min(1).max(MAX_MESSAGE_CHARS),
          })
          .strict(),
      )
      .min(1)
      .max(MAX_MESSAGES),
  })
  .strict();

export interface ParsedRequest extends RetrievalRequest {
  requestId?: string;
  installationId?: string;
  attestationToken?: string;
}

/**
 * Validates the body. The error message is fixed text: it never repeats what
 * the user sent.
 */
export function parseRetrievalRequest(body: unknown): ParsedRequest {
  const r = requestSchema.safeParse(body);
  if (!r.success) throw badRequest('invalid_request', 'The request is not valid.');
  const { messages } = r.data;
  if (messages[messages.length - 1].role !== 'user') {
    throw badRequest('invalid_request', 'The last message must be from the user.');
  }
  if (messages.reduce((n, m) => n + m.text.length, 0) > MAX_TOTAL_CHARS) {
    throw badRequest('request_too_large', 'The conversation is too long.');
  }
  return {
    requestId: r.data.requestId,
    installationId: r.data.installationId,
    attestationToken: r.data.attestationToken,
    mode: r.data.mode, scope: r.data.scope,
    messages,
  };
}
