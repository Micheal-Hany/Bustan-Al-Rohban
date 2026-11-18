import { Hit } from './bm25-index';

/**
 * The measurable "sufficient evidence" rule (SPEC 7.6, step 4). Coverage is
 * the share of the question's weight (sum of term IDF) that the passages
 * contain; query terms found nowhere in the book still count in the total,
 * so an unsupported question scores low.
 *
 *   single-passage rule: top passage coverage >= minTopCoverage
 *                        and it matches >= min(minMatchedTerms, #terms)
 *   multi-passage rule : the top [unionPassages] passages together reach
 *                        >= minUnionCoverage with >= 2 terms (#terms >= 2)
 *
 * These numbers are provisional: they are tuned and evaluated on the real
 * book in Task 13 (results on the FAKE fixture prove plumbing only).
 */
export const EVIDENCE_RULE = {
  minTopCoverage: 0.6,
  minMatchedTerms: 2,
  unionPassages: 3,
  minUnionCoverage: 0.85,
} as const;

export interface EvidenceReport {
  sufficient: boolean;
  queryTerms: number;
  topCoverage: number;
  unionCoverage: number;
  topMatched: number;
}

export function assessEvidence(
  queryTerms: readonly string[],
  hits: readonly Hit[],
  idf: (term: string) => number,
  rule: typeof EVIDENCE_RULE = EVIDENCE_RULE,
): EvidenceReport {
  const unique = [...new Set(queryTerms)];
  const total = unique.reduce((s, t) => s + idf(t), 0);
  const empty: EvidenceReport = {
    sufficient: false,
    queryTerms: unique.length,
    topCoverage: 0,
    unionCoverage: 0,
    topMatched: 0,
  };
  if (unique.length === 0 || total <= 0 || hits.length === 0) return empty;

  const coverage = (terms: Iterable<string>): number => {
    let s = 0;
    for (const t of terms) s += idf(t);
    return s / total;
  };

  const top = hits[0];
  const topCoverage = coverage(top.matched);
  const union = new Set<string>();
  for (const h of hits.slice(0, rule.unionPassages)) for (const t of h.matched) union.add(t);
  const unionCoverage = coverage(union);

  const single =
    topCoverage >= rule.minTopCoverage &&
    top.matched.size >= Math.min(rule.minMatchedTerms, unique.length);
  const multi = unique.length >= 2 && unionCoverage >= rule.minUnionCoverage && union.size >= 2;

  return {
    sufficient: single || multi,
    queryTerms: unique.length,
    topCoverage,
    unionCoverage,
    topMatched: top.matched.size,
  };
}
