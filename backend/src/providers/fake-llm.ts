import { LlmProvider, LlmRequest, LlmResponse } from './llm.port';

/**
 * Behaviours of the deterministic fake. "grounded" is the well-behaved model;
 * the others simulate a failing or manipulated model so the evaluation can
 * prove the validators catch it (they say nothing about real model quality:
 * the same set is run against real providers in Task 10c).
 */
export type FakeBehavior =
  | 'grounded'
  | 'forged_citation'
  | 'altered_quote'
  | 'uncited'
  | 'absolve'
  | 'cite_other_saint'
  | 'not_in_book'
  | 'garbage'
  | 'grounded_after_retry';

export class FakeLlmProvider implements LlmProvider {
  /** Number of calls received (tests assert "no model call" with this). */
  calls = 0;
  /** Every request received, for prompt assertions in tests. */
  readonly seen: LlmRequest[] = [];

  constructor(
    private readonly behavior: FakeBehavior = 'grounded',
    /** Id used by cite_other_saint (a paragraph NOT in the retrieved set). */
    private readonly foreignId = 'p-000005',
  ) {}

  generate(req: LlmRequest): Promise<LlmResponse> {
    this.calls++;
    this.seen.push(req);
    const top = req.passages[0];
    const b = this.behavior === 'grounded_after_retry'
      ? (req.retryFeedback ? 'grounded' : 'altered_quote')
      : this.behavior;
    let out: unknown;
    switch (b) {
      case 'grounded':
        out = {
          status: 'answered',
          blocks: [
            { type: 'quotation', text: top.text, citations: [top.paragraphId] },
            { type: 'paraphrase', text: 'تلخيص أمين لما ورد في الفقرة المذكورة.', citations: [top.paragraphId] },
          ],
        };
        break;
      case 'forged_citation':
        out = { status: 'answered', blocks: [{ type: 'paraphrase', text: 'كلام', citations: ['p-999999'] }] };
        break;
      case 'cite_other_saint':
        out = { status: 'answered', blocks: [{ type: 'paraphrase', text: 'كلام', citations: [this.foreignId] }] };
        break;
      case 'altered_quote':
        out = {
          status: 'answered',
          blocks: [{ type: 'quotation', text: `${top.text} وزيادة لم ترد في الكتاب`, citations: [top.paragraphId] }],
        };
        break;
      case 'uncited':
        out = { status: 'answered', blocks: [{ type: 'paraphrase', text: 'كلام بلا مصدر', citations: [] }] };
        break;
      case 'absolve':
        out = {
          status: 'answered',
          blocks: [{ type: 'paraphrase', text: 'أنا أحلك من خطاياك الآن.', citations: [top.paragraphId] }],
        };
        break;
      case 'not_in_book':
        out = { status: 'not_in_book', blocks: [] };
        break;
      default:
        return Promise.resolve({ text: 'not json {{', provider: 'fake', model: 'fake-1' });
    }
    return Promise.resolve({
      text: JSON.stringify(out),
      provider: 'fake',
      model: 'fake-1',
      usage: { inputTokens: req.prompt.length, outputTokens: 50 },
    });
  }
}
