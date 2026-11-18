import { AliasTable } from '../src/retrieval/alias-table';
import { Bm25Index, Hit } from '../src/retrieval/bm25-index';
import { assessEvidence, EVIDENCE_RULE } from '../src/retrieval/evidence';
import { Passage, SaintInfo } from '../src/sources/corpus.types';

const saints: SaintInfo[] = [
  { id: 's-anton', title: '[تجريبي] الأنبا أنطونيوس', aliases: ['أنطونيوس', 'أنطونيوس الكبير', 'القديس أنطونيوس'], sectionIds: [] },
  { id: 's-pach', title: '[تجريبي] الأنبا باخوميوس', aliases: ['باخوميوس', 'أنطونيوس'], sectionIds: [] },
  { id: 's-mak', title: '[تجريبي] الأنبا مقار', aliases: ['مقاريوس', 'مقار'], sectionIds: [] },
];

describe('alias table', () => {
  const t = new AliasTable(saints);

  it('resolves variants with different diacritics and spellings', () => {
    expect(t.resolve('ماذا قال مَقَارِيُوس؟')).toEqual(['s-mak']);
    expect(t.resolve('عن الأنبا مقار')).toEqual(['s-mak']);
    expect(t.resolve('عن الانبا مقار')).toEqual(['s-mak']);
  });

  it('matches whole words only', () => {
    expect(t.resolve('مقارنة بين الصوم والصلاة')).toEqual([]);
  });

  it('prefers the longest alias', () => {
    const m = t.find('أنطونيوس الكبير');
    expect(m).toEqual([{ saintId: 's-anton', start: 0, end: 2 }]); // not the shared short alias
  });

  it('an alias shared by two saints resolves to both (ambiguity is visible)', () => {
    expect(t.resolve('أنطونيوس').sort()).toEqual(['s-anton', 's-pach']);
  });

  it('handles a leading conjunction letter', () => {
    expect(t.resolve('وباخوميوس')).toEqual(['s-pach']);
  });

  it('finds several saints in order of appearance', () => {
    expect(t.resolve('قارن باخوميوس ومقار')).toEqual(['s-pach', 's-mak']);
  });

  it('no saint, no match', () => {
    expect(t.resolve('ما هو الصوم؟')).toEqual([]);
  });
});

const passage = (id: string, text: string): Passage => ({
  paragraphId: id,
  bookId: 'b',
  saintId: 's',
  saintTitle: 't',
  sectionId: 'sec',
  sectionTitle: 't',
  page: null,
  kind: 'body',
  text,
  contentVersion: 1,
});

describe('evidence rule', () => {
  const index = new Bm25Index([
    passage('1', 'صوم صلاة طاعة'),
    passage('2', 'تواضع محبة'),
    passage('3', 'صبر رجاء'),
    passage('4', 'كلام آخر مختلف'),
    passage('5', 'نص رقم خمسة'),
    passage('6', 'نص رقم ستة'),
  ]);
  const run = (terms: string[]) => {
    const hits = index.search(terms, () => true);
    return assessEvidence(terms, hits, (t) => index.idf(t));
  };

  it('all terms in one passage: sufficient', () => {
    const r = run(['صوم', 'صلاه']);
    expect(r.sufficient).toBe(true);
    expect(r.topCoverage).toBeCloseTo(1);
  });

  it('terms unknown to the book lower coverage and refuse', () => {
    const r = run(['صوم', 'فضاء', 'كواكب']);
    expect(r.sufficient).toBe(false);
    expect(r.topCoverage).toBeLessThan(EVIDENCE_RULE.minTopCoverage);
  });

  it('terms spread over passages pass only if the union is high enough', () => {
    const r = run(['صوم', 'تواضع', 'صبر']);
    expect(r.unionCoverage).toBeGreaterThanOrEqual(EVIDENCE_RULE.minUnionCoverage);
    expect(r.sufficient).toBe(true);
    const r2 = run(['صوم', 'تواضع', 'صبر', 'مجهول']);
    expect(r2.sufficient).toBe(false);
  });

  it('a single term that is in the book is enough; one that is not is refused', () => {
    expect(run(['صوم']).sufficient).toBe(true);
    expect(run(['مجهول']).sufficient).toBe(false);
  });

  it('no terms or no hits is never sufficient', () => {
    expect(assessEvidence([], [], () => 1).sufficient).toBe(false);
    expect(run([]).sufficient).toBe(false);
  });

  it('boundary: coverage exactly at the threshold passes, just under fails', () => {
    const fake = (matched: string[]): Hit => ({ passage: passage('x', ''), score: 1, matched: new Set(matched) });
    const idf = () => 1;
    // 3 of 5 equal-weight terms = 0.6 = minTopCoverage, 3 matched >= 2.
    expect(assessEvidence(['a', 'b', 'c', 'd', 'e'], [fake(['a', 'b', 'c'])], idf).sufficient).toBe(true);
    // 2 of 5 = 0.4 < 0.6.
    expect(assessEvidence(['a', 'b', 'c', 'd', 'e'], [fake(['a', 'b'])], idf).sufficient).toBe(false);
  });
});

describe('scope filter is part of the query', () => {
  it('a passage outside the allowed scope is never returned', () => {
    const a = { ...passage('1', 'صوم'), saintId: 'x' };
    const b = { ...passage('2', 'صوم صوم صوم'), saintId: 'y' };
    const index = new Bm25Index([a, b]);
    const hits = index.search(['صوم'], (p) => p.saintId === 'x');
    expect(hits.map((h) => h.passage.paragraphId)).toEqual(['1']);
  });
});
