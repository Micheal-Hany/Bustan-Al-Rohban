/**
 * Arabic normalization and tokenization for the retrieval index. It never
 * changes passage text: only the index/query forms are folded.
 *
 * Same folding as the app's local search (lib/core/search/arabic_normalizer.dart):
 * diacritics, tatweel and zero-width marks are dropped; alef variants -> ا;
 * ى -> ي; ة -> ه; Arabic-Indic/Persian digits -> ASCII; everything that is not a
 * letter or digit separates tokens. Hamza on waw/ya (ؤ ئ) is left unchanged.
 */

const DROP = 0;
const SEPARATOR = -1;

function fold(c: number): number {
  if (c === 0x0640) return DROP; // tatweel
  if ((c >= 0x064b && c <= 0x065f) || c === 0x0670) return DROP;
  if (
    (c >= 0x06d6 && c <= 0x06dc) ||
    (c >= 0x06df && c <= 0x06e4) ||
    c === 0x06e7 ||
    c === 0x06e8 ||
    (c >= 0x06ea && c <= 0x06ed)
  ) {
    return DROP;
  }
  if (
    (c >= 0x200b && c <= 0x200f) ||
    c === 0x061c ||
    c === 0xfeff ||
    c === 0x00ad ||
    (c >= 0x202a && c <= 0x202e)
  ) {
    return DROP;
  }
  switch (c) {
    case 0x0622:
    case 0x0623:
    case 0x0625:
    case 0x0671:
      return 0x0627; // ا
    case 0x0649:
      return 0x064a; // ي
    case 0x0629:
      return 0x0647; // ه
  }
  if (c >= 0x0660 && c <= 0x0669) return 0x30 + (c - 0x0660);
  if (c >= 0x06f0 && c <= 0x06f9) return 0x30 + (c - 0x06f0);
  if (
    (c >= 0x0621 && c <= 0x064a) ||
    (c >= 0x066e && c <= 0x06d3) ||
    (c >= 0x06fa && c <= 0x06ff)
  ) {
    return c;
  }
  if (c >= 0x30 && c <= 0x39) return c;
  if (c >= 0x41 && c <= 0x5a) return c + 0x20;
  if (c >= 0x61 && c <= 0x7a) return c;
  if (c >= 0xc0 && c <= 0x24f && c !== 0xd7 && c !== 0xf7) return c;
  return SEPARATOR;
}

/** Normalized word tokens of [text] (no stemming, no stop-word removal). */
export function tokenize(text: string): string[] {
  const tokens: string[] = [];
  let buf = '';
  for (const ch of text) {
    const code = ch.codePointAt(0) as number;
    const f = code > 0xffff ? SEPARATOR : fold(code);
    if (f === DROP) continue;
    if (f === SEPARATOR) {
      if (buf) tokens.push(buf);
      buf = '';
    } else {
      buf += String.fromCharCode(f);
    }
  }
  if (buf) tokens.push(buf);
  return tokens;
}

/** Normalized whole string (tokens joined by one space). */
export function normalize(text: string): string {
  return tokenize(text).join(' ');
}

/**
 * Very common function words (already in normalized form). A question made
 * only of these has no content to look up.
 */
export const STOP_WORDS: ReadonlySet<string> = new Set(
  [
    'في', 'من', 'على', 'الى', 'عن', 'ما', 'ماذا', 'هل', 'هو', 'هي', 'هم', 'هذا',
    'هذه', 'ذلك', 'تلك', 'التي', 'الذي', 'الذين', 'ان', 'كان', 'كانت', 'يكون',
    'لا', 'لم', 'لن', 'قد', 'ثم', 'او', 'و', 'يا', 'اي', 'كيف', 'لماذا', 'متي',
    'اين', 'مع', 'بين', 'كل', 'بعض', 'عند', 'حول', 'قال', 'يقول', 'اذكر',
    'اخبرني', 'اشرح', 'ما هي', 'له', 'لها', 'به', 'بها', 'فيه', 'فيها', 'منه',
    'منها', 'كتاب', 'الكتاب', 'بستان', 'رهبان', 'الرهبان', 'قارن', 'بين', 'وضح', 'لخص', 'فسر', 'حدثني', 'تحدث', 'عرف', 'ماهو', 'ماهي', 'عنه', 'عنها', 'انه', 'انها', 'لكن', 'اذا', 'حتي', 'ايضا', 'كما',
    // Request wording (quotation / page asks) is not evidence.
    'اقتبس', 'اقتباس', 'اقتباسا', 'حرفيا', 'رقم', 'صفحه', 'الصفحه', 'اكتب', 'اعطني', 'اريد',
  ].flatMap((w) => tokenize(w)),
);

const PREFIXES = ['وبال', 'وكال', 'وفال', 'وال', 'بال', 'كال', 'فال', 'لل', 'ال'];

/**
 * Light stemming: strips a leading definite article (with an optional
 * conjunction/preposition) when at least 3 letters remain. Deliberately
 * conservative; heavier stemming hurts precision on a small corpus.
 */
export function stem(token: string): string {
  for (const p of PREFIXES) {
    if (token.startsWith(p) && token.length - p.length >= 3) {
      return token.slice(p.length);
    }
  }
  return token;
}

/** Index/query terms of [text]: normalized, stop words removed, stemmed. */
export function terms(text: string): string[] {
  return tokenize(text)
    .filter((t) => !STOP_WORDS.has(t))
    .map(stem)
    .filter((t) => t.length > 1 || /^\d$/.test(t));
}

/** Like [terms] but starts from tokens that were already produced. */
export function termsFromTokens(tokens: readonly string[]): string[] {
  return tokens
    .filter((t) => !STOP_WORDS.has(t))
    .map(stem)
    .filter((t) => t.length > 1 || /^\d$/.test(t));
}
