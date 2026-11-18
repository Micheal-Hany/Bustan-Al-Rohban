import { normalize } from '../retrieval/arabic';

/**
 * Phrases a generated answer must never contain (SPEC 6.3): personal
 * absolution, impersonating clergy, or presenting itself as an official church
 * statement. Written in normalized form (no diacritics; ا ي ه folded) and
 * matched on normalized text. Deliberately small and conservative; the owner
 * extends it during review.
 */
export const FORBIDDEN_PHRASES: readonly string[] = [
  'انا احللك',
  'احلك من',
  'خطاياك مغفوره',
  'خطيتك مغفوره',
  'مغفوره لك',
  'اغفر لك',
  'انا كاهن',
  'بصفتي كاهن',
  'بصفتي اب اعترافك',
  'انا اب اعترافك',
  'بيان رسمي من الكنيسه',
  'تعلن الكنيسه رسميا',
];

const NORMALIZED = FORBIDDEN_PHRASES.map(normalize);

/** The matched forbidden phrase, or null. */
export function checkForbiddenContent(text: string): string | null {
  const n = ` ${normalize(text)} `;
  for (const p of NORMALIZED) if (n.includes(` ${p} `) || n.includes(p)) return p;
  return null;
}
