import { Passage } from '../sources/corpus.types';
import { terms } from './arabic';

const K1 = 1.2;
const B = 0.75;

export interface Hit {
  passage: Passage;
  score: number;
  /** Distinct query terms found in this passage. */
  matched: ReadonlySet<string>;
}

/** In-memory lexical (BM25) index over passages. Text is never modified. */
export class Bm25Index {
  private readonly postings = new Map<string, { doc: number; tf: number }[]>();
  private readonly lengths: number[] = [];
  private readonly avgLength: number;

  constructor(private readonly passages: readonly Passage[]) {
    passages.forEach((p, doc) => {
      const counts = new Map<string, number>();
      const ts = terms(p.text);
      for (const t of ts) counts.set(t, (counts.get(t) ?? 0) + 1);
      this.lengths.push(ts.length);
      for (const [t, tf] of counts) {
        const list = this.postings.get(t);
        if (list) list.push({ doc, tf });
        else this.postings.set(t, [{ doc, tf }]);
      }
    });
    const total = this.lengths.reduce((a, b) => a + b, 0);
    this.avgLength = passages.length ? total / passages.length : 0;
  }

  get size(): number {
    return this.passages.length;
  }

  /** Inverse document frequency over the whole corpus (0 postings => highest). */
  idf(term: string): number {
    const n = this.postings.get(term)?.length ?? 0;
    return Math.log(1 + (this.passages.length - n + 0.5) / (n + 0.5));
  }

  /**
   * Scores passages for [queryTerms]. [allow] is applied while walking the
   * postings, so a passage outside the scope is never scored or returned:
   * the scope filter is part of the query, not a post-filter.
   */
  search(
    queryTerms: readonly string[],
    allow: (p: Passage) => boolean,
    boost: (p: Passage) => number = () => 1,
  ): Hit[] {
    const scores = new Map<number, number>();
    const matched = new Map<number, Set<string>>();
    for (const t of new Set(queryTerms)) {
      const list = this.postings.get(t);
      if (!list) continue;
      const idf = this.idf(t);
      for (const { doc, tf } of list) {
        const passage = this.passages[doc];
        if (!allow(passage)) continue;
        const norm = 1 - B + B * (this.lengths[doc] / (this.avgLength || 1));
        const s = idf * ((tf * (K1 + 1)) / (tf + K1 * norm));
        scores.set(doc, (scores.get(doc) ?? 0) + s);
        let set = matched.get(doc);
        if (!set) matched.set(doc, (set = new Set()));
        set.add(t);
      }
    }
    const hits: Hit[] = [];
    for (const [doc, score] of scores) {
      const passage = this.passages[doc];
      hits.push({ passage, score: score * boost(passage), matched: matched.get(doc) as Set<string> });
    }
    // Highest score first; ties broken by paragraph id for a stable order.
    hits.sort(
      (a, b) => b.score - a.score || a.passage.paragraphId.localeCompare(b.passage.paragraphId),
    );
    return hits;
  }
}
