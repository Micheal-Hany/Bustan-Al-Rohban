import { SaintInfo } from '../sources/corpus.types';
import { tokenize } from './arabic';

const PREFIX_LETTERS = ['و', 'ف', 'ب', 'ل', 'ك'];

/** Strips a leading conjunction/preposition letter when 3+ letters remain. */
function withoutPrefix(token: string): string {
  return token.length > 3 && PREFIX_LETTERS.includes(token[0]) ? token.slice(1) : token;
}

/** A mention of a saint inside a question. */
export interface AliasMatch {
  saintId: string;
  /** Token range [start, end) of the matched alias inside the query tokens. */
  start: number;
  end: number;
}

/**
 * Maps saint name variants (title and aliases from the manifest) to saint ids.
 * Matching is on normalized whole-word token sequences, so "القديس الأول"
 * matches "القديسُ الأوَّل" but not part of a longer word.
 */
export class AliasTable {
  private readonly entries: { tokens: string[]; saintId: string }[] = [];

  constructor(saints: readonly SaintInfo[]) {
    for (const s of saints) {
      const names = new Set<string>();
      names.add(s.title);
      // A title like "[تجريبي] القديس الأول": also index it without the tag.
      names.add(s.title.replace(/^\s*\[[^\]]*\]\s*/, ''));
      for (const a of s.aliases) names.add(a);
      for (const n of names) {
        const tokens = tokenize(n);
        if (tokens.length === 0) continue;
        if (!this.entries.some((e) => e.saintId === s.id && e.tokens.join(' ') === tokens.join(' '))) {
          this.entries.push({ tokens, saintId: s.id });
        }
      }
    }
    // Longest names first so "X الكبير" wins over "X".
    this.entries.sort((a, b) => b.tokens.length - a.tokens.length);
  }

  /**
   * All saint mentions in [text], in order of appearance. An alias shared by
   * several saints yields one match per saint (the caller sees the ambiguity).
   */
  find(text: string): AliasMatch[] {
    const raw = tokenize(text);
    const stripped = raw.map(withoutPrefix);
    const taken = new Array<boolean>(raw.length).fill(false);
    const out: AliasMatch[] = [];
    for (const e of this.entries) {
      const n = e.tokens.length;
      for (let i = 0; i + n <= raw.length; i++) {
        if (taken.slice(i, i + n).some(Boolean)) continue;
        const direct = e.tokens.every((t, k) => raw[i + k] === t);
        const viaPrefix = e.tokens.every((t, k) => (k === 0 ? stripped[i] : raw[i + k]) === t);
        if (direct || viaPrefix) {
          out.push({ saintId: e.saintId, start: i, end: i + n });
          // Do not block other saints that share exactly this alias.
          const sharers = this.entries.filter(
            (o) => o !== e && o.tokens.join(' ') === e.tokens.join(' '),
          );
          if (sharers.length === 0) for (let k = i; k < i + n; k++) taken[k] = true;
        }
      }
    }
    out.sort((a, b) => a.start - b.start);
    return out;
  }

  /** Distinct saint ids mentioned in [text], in order of first mention. */
  resolve(text: string): string[] {
    return [...new Set(this.find(text).map((m) => m.saintId))];
  }
}
