import { RetrievedPassage } from '../retrieval/retrieval.types';

/** What a model adapter receives. Real adapters use [system] + [prompt]; the
 * structured fields let fakes and tests work without parsing prompts. */
export interface LlmRequest {
  system: string;
  prompt: string;
  question: string;
  passages: RetrievedPassage[];
  /** Set on the single retry: error codes of the previous attempt. */
  retryFeedback?: string[];
}

export interface LlmUsage {
  inputTokens?: number;
  outputTokens?: number;
}

export interface LlmResponse {
  /** Raw model output; must be JSON in the structured-answer schema. */
  text: string;
  provider: string;
  model: string;
  usage?: LlmUsage;
}

/** Provider-agnostic port. OpenAI and Gemini adapters arrive in Task 10c. */
export interface LlmProvider {
  generate(req: LlmRequest): Promise<LlmResponse>;
}

export const LLM_PROVIDER = 'LLM_PROVIDER';

export type ProviderErrorKind =
  | 'timeout'
  | 'rate_limited'
  | 'auth'
  | 'bad_request'
  | 'server'
  | 'network'
  | 'bad_response';

/**
 * Failure of a provider call. The message is fixed text built from the kind:
 * it never contains the provider's response body, the prompt or the key.
 */
export class ProviderError extends Error {
  constructor(readonly kind: ProviderErrorKind) {
    super(`provider_${kind}`);
  }
}
