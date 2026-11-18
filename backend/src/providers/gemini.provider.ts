import { FetchFn, num, postJson } from './http';
import { LlmProvider, LlmRequest, LlmResponse, ProviderError } from './llm.port';
import { AdapterOptions } from './openai.provider';

/** Gemini generateContent (JSON mime type). Key goes in a header, never the URL. */
export class GeminiProvider implements LlmProvider {
  constructor(private readonly o: AdapterOptions) {}

  async generate(req: LlmRequest): Promise<LlmResponse> {
    const fetchFn: FetchFn = this.o.fetchFn ?? fetch;
    const json = (await postJson(
      fetchFn,
      `${this.o.baseUrl ?? 'https://generativelanguage.googleapis.com'}/v1beta/models/${encodeURIComponent(this.o.model)}:generateContent`,
      { 'x-goog-api-key': this.o.apiKey },
      {
        systemInstruction: { parts: [{ text: req.system }] },
        contents: [{ role: 'user', parts: [{ text: req.prompt }] }],
        generationConfig: {
          temperature: 0,
          maxOutputTokens: this.o.maxOutputTokens,
          responseMimeType: 'application/json',
        },
      },
      this.o.timeoutMs,
    )) as {
      candidates?: { content?: { parts?: { text?: unknown }[] } }[];
      usageMetadata?: { promptTokenCount?: unknown; candidatesTokenCount?: unknown };
    };
    const parts = json?.candidates?.[0]?.content?.parts;
    // A blocked or empty candidate has no parts: that is a bad response.
    const text = Array.isArray(parts)
      ? parts.map((p) => (typeof p?.text === 'string' ? p.text : '')).join('')
      : '';
    if (text.trim() === '') throw new ProviderError('bad_response');
    const input = num(json.usageMetadata?.promptTokenCount);
    const output = num(json.usageMetadata?.candidatesTokenCount);
    return {
      text,
      provider: 'gemini',
      model: this.o.model,
      usage: input !== undefined && output !== undefined ? { inputTokens: input, outputTokens: output } : undefined,
    };
  }
}
