import { z } from 'zod';

export const MAX_BLOCK_CHARS = 1500;
export const MAX_BLOCKS = 12;

/**
 * The structured answer a model must return (SPEC 6.2: quotation, paraphrase
 * and cautious inference are kept apart so the UI can show them differently).
 */
export const modelAnswerSchema = z
  .object({
    status: z.enum(['answered', 'not_in_book']),
    blocks: z
      .array(
        z
          .object({
            type: z.enum(['quotation', 'paraphrase', 'inference']),
            text: z.string().trim().min(1).max(MAX_BLOCK_CHARS),
            /** Paragraph ids from the passages given for THIS request. */
            citations: z.array(z.string().min(1).max(100)).max(10),
          })
          .strict(),
      )
      .max(MAX_BLOCKS),
  })
  .strict();

export type ModelAnswer = z.infer<typeof modelAnswerSchema>;
export type AnswerBlock = ModelAnswer['blocks'][number];
