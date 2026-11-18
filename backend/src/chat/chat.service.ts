import { Inject, Injectable } from '@nestjs/common';
import { AppError } from '../common/app-error';
import { LLM_PROVIDER, LlmProvider, LlmUsage } from '../providers/llm.port';
import { REFUSAL_MESSAGE, RetrievalService } from '../retrieval/retrieval.service';
import { RetrievalRequest, RetrievedPassage } from '../retrieval/retrieval.types';
import {
  PASTORAL_NOTE,
  Referral,
  SAFETY_RESPONSES,
  SafetyCategory,
  classifySafety,
  isSensitiveTopic,
} from '../theological-policy/safety';
import { SYSTEM_PROMPT, buildPrompt } from '../theological-policy/system-prompt';
import { AnswerBlock } from './answer.schema';
import { ValidationCode, validateModelOutput } from './validation';

export interface Reference {
  paragraphId: string;
  saintId: string;
  saintTitle: string;
  sectionId: string;
  sectionTitle: string;
  page: number | null;
}

export type ChatOutcome =
  | 'answered'
  | 'refused_retrieval'
  | 'refused_model'
  | 'refused_validation'
  | 'safety';

export type ChatResponse =
  | {
      status: 'answered';
      blocks: (AnswerBlock & { references: Reference[] })[];
      pastoralNote?: string;
      meta: { provider: string; model: string; usage?: LlmUsage; attempts: number };
    }
  | {
      status: 'refused';
      reason: string;
      message: string;
      suggestedSaintIds?: string[];
    }
  | {
      status: 'safety';
      category: SafetyCategory;
      referral: Referral[];
      message: string;
    };

export interface ChatResult {
  response: ChatResponse;
  outcome: ChatOutcome;
  attempts: number;
  validationCodes?: ValidationCode[];
}

/** Fixed text when the model's output could not be validated (SPEC 7.6). */
export const UNVALIDATED_MESSAGE = 'تعذّر إعداد إجابة موثوقة من الكتاب لهذا السؤال. حاول إعادة صياغة السؤال.';

const MAX_ATTEMPTS = 2;

/**
 * Request flow of SPEC 7.6 for the stateless chat endpoint:
 * scope check -> safety pre-check (no model) -> retrieval (+ sufficient
 * evidence) -> model -> validation (+ one corrective retry) -> answer.
 * Non-streaming: validation needs the complete output (docs/AI_POLICY.md).
 */
@Injectable()
export class ChatService {
  constructor(
    @Inject(RetrievalService) private readonly retrieval: RetrievalService,
    @Inject(LLM_PROVIDER) private readonly llm: LlmProvider,
  ) {}

  async answer(req: RetrievalRequest): Promise<ChatResult> {
    this.retrieval.validateScope(req);
    const question = req.messages[req.messages.length - 1].text;

    const safety = classifySafety(question);
    if (safety) {
      const s = SAFETY_RESPONSES[safety];
      return {
        outcome: 'safety',
        attempts: 0,
        response: { status: 'safety', category: s.category, referral: s.referral, message: s.message },
      };
    }

    const found = this.retrieval.retrieve(req);
    if (found.status === 'refused') {
      return {
        outcome: 'refused_retrieval',
        attempts: 0,
        response: {
          status: 'refused',
          reason: found.reason,
          message: found.message,
          suggestedSaintIds: found.suggestedSaintIds,
        },
      };
    }

    const passages = found.passages;
    let feedback: string[] | undefined;
    let lastCodes: ValidationCode[] = [];
    for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
      let raw;
      try {
        raw = await this.llm.generate({
          system: SYSTEM_PROMPT,
          prompt: buildPrompt(passages, req.messages, feedback),
          question,
          passages,
          retryFeedback: feedback,
        });
      } catch {
        // Provider details are never forwarded to the client.
        throw new AppError(502, 'provider_error', 'The answer service is unavailable.');
      }
      const v = validateModelOutput(raw.text, passages);
      if (v.ok) {
        if (v.status === 'not_in_book') {
          return {
            outcome: 'refused_model',
            attempts: attempt,
            response: { status: 'refused', reason: 'not_in_book', message: REFUSAL_MESSAGE },
          };
        }
        return {
          outcome: 'answered',
          attempts: attempt,
          response: {
            status: 'answered',
            blocks: v.blocks.map((b) => ({ ...b, references: this.refs(b.citations, passages) })),
            pastoralNote: isSensitiveTopic(question) ? PASTORAL_NOTE : undefined,
            meta: { provider: raw.provider, model: raw.model, usage: raw.usage, attempts: attempt },
          },
        };
      }
      lastCodes = v.codes;
      feedback = v.codes;
    }
    return {
      outcome: 'refused_validation',
      attempts: MAX_ATTEMPTS,
      validationCodes: lastCodes,
      response: { status: 'refused', reason: 'validation_failed', message: UNVALIDATED_MESSAGE },
    };
  }

  private refs(ids: string[], passages: readonly RetrievedPassage[]): Reference[] {
    return ids.map((id) => {
      const p = passages.find((x) => x.paragraphId === id) as RetrievedPassage;
      return {
        paragraphId: p.paragraphId,
        saintId: p.saintId,
        saintTitle: p.saintTitle,
        sectionId: p.sectionId,
        sectionTitle: p.sectionTitle,
        page: p.page,
      };
    });
  }
}
