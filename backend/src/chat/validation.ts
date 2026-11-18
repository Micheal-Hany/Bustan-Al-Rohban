import { RetrievedPassage } from '../retrieval/retrieval.types';
import { checkForbiddenContent } from '../theological-policy/forbidden';
import { AnswerBlock, ModelAnswer, modelAnswerSchema } from './answer.schema';

export type ValidationCode =
  | 'bad_json'
  | 'bad_schema'
  | 'no_blocks'
  | 'citation_missing'
  | 'citation_not_retrieved'
  | 'quote_not_verbatim'
  | 'forbidden_content';

export type ValidationResult =
  | { ok: true; status: 'answered' | 'not_in_book'; blocks: AnswerBlock[] }
  | { ok: false; codes: ValidationCode[] };

/** Collapses whitespace runs (line breaks vs spaces) before comparing. */
const squash = (s: string): string => s.normalize('NFC').replace(/\s+/g, ' ').trim();

/** True when [quote] occurs verbatim in [passageText] (whitespace-insensitive). */
export function isVerbatim(quote: string, passageText: string): boolean {
  const q = squash(quote);
  return q.length > 0 && squash(passageText).includes(q);
}

/**
 * Checks a raw model output against the passages retrieved for this request
 * (SPEC 7.6 steps 7-8). Nothing the model says is trusted:
 *  - the output must match the schema;
 *  - every block cites at least one passage, and every cited id must be one of
 *    the retrieved passages;
 *  - every quotation must be a verbatim substring of one of the passages it
 *    cites (not just of any passage);
 *  - no absolution, clergy impersonation or official-church-statement claims.
 */
export function validateModelOutput(
  raw: string,
  retrieved: readonly RetrievedPassage[],
): ValidationResult {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return { ok: false, codes: ['bad_json'] };
  }
  const schema = modelAnswerSchema.safeParse(parsed);
  if (!schema.success) return { ok: false, codes: ['bad_schema'] };
  const answer: ModelAnswer = schema.data;

  if (answer.status === 'not_in_book') {
    return { ok: true, status: 'not_in_book', blocks: [] };
  }
  if (answer.blocks.length === 0) return { ok: false, codes: ['no_blocks'] };

  const byId = new Map(retrieved.map((p) => [p.paragraphId, p]));
  const codes = new Set<ValidationCode>();
  for (const block of answer.blocks) {
    if (block.citations.length === 0) {
      codes.add('citation_missing');
      continue;
    }
    const cited = block.citations.map((id) => byId.get(id));
    if (cited.some((p) => p === undefined)) {
      codes.add('citation_not_retrieved');
      continue;
    }
    if (
      block.type === 'quotation' &&
      !cited.some((p) => p !== undefined && isVerbatim(block.text, p.text))
    ) {
      codes.add('quote_not_verbatim');
    }
    if (checkForbiddenContent(block.text)) codes.add('forbidden_content');
  }
  return codes.size > 0 ? { ok: false, codes: [...codes] } : { ok: true, status: 'answered', blocks: answer.blocks };
}
