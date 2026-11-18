import { Inject, Injectable } from '@nestjs/common';
import { badRequest } from '../common/app-error';
import { CorpusService } from '../sources/corpus.service';
import { Passage } from '../sources/corpus.types';
import { AliasTable } from './alias-table';
import { termsFromTokens, tokenize } from './arabic';
import { Bm25Index } from './bm25-index';
import { assessEvidence } from './evidence';
import { RetrievalRequest, RetrievalResult } from './retrieval.types';

/** Shown to the user when the book has no answer. Fixed text, no model call. */
export const REFUSAL_MESSAGE = 'لم أجد في كتاب بستان الرهبان ما يجيب عن هذا السؤال.';

export const MAX_PASSAGES = 6;
const MENTION_BOOST = 1.5;

@Injectable()
export class RetrievalService {
  private readonly index: Bm25Index;
  private readonly aliases: AliasTable;

  constructor(@Inject(CorpusService) private readonly source: CorpusService) {
    this.index = new Bm25Index(source.corpus.passages);
    this.aliases = new AliasTable(source.corpus.saints);
  }

  /** Throws a 400 for a scope that does not exist in the corpus. */
  validateScope(req: RetrievalRequest): void {
    const c = this.source.corpus;
    const { bookId, saintId, sectionId } = req.scope;
    if (bookId !== undefined && bookId !== c.bookId) {
      throw badRequest('unknown_book', 'The requested book is not available.');
    }
    if (req.mode === 'book_scope') {
      if (saintId !== undefined || sectionId !== undefined) {
        throw badRequest('scope_mismatch', 'book_scope takes no saint or section.');
      }
      return;
    }
    if (saintId === undefined) {
      throw badRequest('scope_mismatch', 'saint_scope needs a saintId.');
    }
    const saint = c.saints.find((s) => s.id === saintId);
    if (!saint) throw badRequest('unknown_saint', 'The requested saint is not available.');
    if (sectionId !== undefined && !saint.sectionIds.includes(sectionId)) {
      throw badRequest('unknown_section', 'The requested section is not available.');
    }
  }

  /**
   * Retrieval for the LAST user message. The scope comes only from the
   * request's scope fields: earlier messages and the wording of the question
   * can never widen it.
   */
  retrieve(req: RetrievalRequest): RetrievalResult {
    this.validateScope(req);
    const question = req.messages[req.messages.length - 1].text;
    const { saintId, sectionId } = req.scope;

    const matches = this.aliases.find(question);
    const mentioned = [...new Set(matches.map((m) => m.saintId))];

    if (req.mode === 'saint_scope') {
      const others = mentioned.filter((id) => id !== saintId);
      if (others.length > 0 && !mentioned.includes(saintId as string)) {
        return {
          status: 'refused',
          reason: 'out_of_scope_saint',
          message: REFUSAL_MESSAGE,
          suggestedSaintIds: others,
        };
      }
    }

    // Saint names are not evidence: drop the tokens of recognised names.
    const tokens = tokenize(question);
    const nameTokens = new Set<number>();
    for (const m of matches) for (let i = m.start; i < m.end; i++) nameTokens.add(i);
    const queryTerms = termsFromTokens(tokens.filter((_, i) => !nameTokens.has(i)));
    if (queryTerms.length === 0) {
      return {
        status: 'refused',
        reason: 'no_searchable_terms',
        message: REFUSAL_MESSAGE,
      };
    }

    const allow = (p: Passage): boolean =>
      req.mode === 'book_scope' ||
      (p.saintId === saintId && (sectionId === undefined || p.sectionId === sectionId));
    const boost = (p: Passage): number =>
      req.mode === 'book_scope' && mentioned.includes(p.saintId) ? MENTION_BOOST : 1;

    const hits = this.index.search(queryTerms, allow, boost);
    const evidence = assessEvidence(queryTerms, hits, (t) => this.index.idf(t));
    if (!evidence.sufficient) {
      return {
        status: 'refused',
        reason: 'insufficient_evidence',
        message: REFUSAL_MESSAGE,
        evidence,
      };
    }
    return {
      status: 'ok',
      mentionedSaintIds: mentioned,
      evidence,
      passages: hits.slice(0, MAX_PASSAGES).map((h) => ({
        paragraphId: h.passage.paragraphId,
        saintId: h.passage.saintId,
        saintTitle: h.passage.saintTitle,
        sectionId: h.passage.sectionId,
        sectionTitle: h.passage.sectionTitle,
        page: h.passage.page,
        kind: h.passage.kind,
        text: h.passage.text,
        score: Number(h.score.toFixed(4)),
      })),
    };
  }
}
