import { FetchFn, num, postJson } from './http';
import { LlmProvider, LlmRequest, LlmResponse, ProviderError } from './llm.port';

export interface AdapterOptions {
  model: string;
  apiKey: string;
  timeoutMs: number;
  maxOutputTokens: number;
  fetchFn?: FetchFn;
  baseUrl?: string;
}

/** OpenAI Chat Completions (JSON mode). Key goes in a header, never the URL. */
export class OpenAiProvider implements LlmProvider {
  constructor(private readonly o: AdapterOptions) {}

  async generate(req: LlmRequest): Promise<LlmResponse> {
    const json = (await postJson(
      this.o.fetchFn ?? fetch,
      `${this.o.baseUrl ?? 'https://api.openai.com'}/v1/chat/completions`,
      { authorization: `Bearer ${this.o.apiKey}` },
      {
        model: this.o.model,
        messages: [
          { role: 'system', content: req.system },
          { role: 'user', content: req.prompt },
        ],
        response_format: { type: 'json_object' },
        temperature: 0,
        max_completion_tokens: this.o.maxOutputTokens,
      },
      this.o.timeoutMs,
    )) as {
      choices?: { message?: { content?: unknown } }[];
      usage?: { prompt_tokens?: unknown; completion_tokens?: unknown };
    };
    const text = json?.choices?.[0]?.message?.content;
    if (typeof text !== 'string' || text.trim() === '') throw new ProviderError('bad_response');
    const input = num(json.usage?.prompt_tokens);
    const output = num(json.usage?.completion_tokens);
    return {
      text,
      provider: 'openai',
      model: this.o.model,
      usage: input !== undefined && output !== undefined ? { inputTokens: input, outputTokens: output } : undefined,
    };
  }
}
