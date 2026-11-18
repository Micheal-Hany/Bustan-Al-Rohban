import { mkdtempSync, writeFileSync, mkdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { assertDeployable, CorpusError, loadCorpus } from '../src/sources/corpus.loader';
import { APP_CONTENT_DIR, fixtureCorpus } from './helpers';

describe('corpus loader', () => {
  it('turns every paragraph into one passage with its metadata', () => {
    const c = fixtureCorpus();
    expect(c.bookId).toBe('bustan-al-rohban');
    expect(c.contentVersion).toBe(7);
    expect(c.saints.map((s) => s.id)).toEqual(['saint-a', 'saint-b', 'saint-c']);
    expect(c.passages).toHaveLength(6);
    const p = c.passages.find((x) => x.paragraphId === 'p-000003');
    expect(p).toMatchObject({
      saintId: 'saint-a',
      sectionId: 'sec-a2',
      page: 2,
      kind: 'body',
      contentVersion: 7,
    });
    expect(p?.text).toContain('الصوم');
  });

  it('keeps the original text untouched', () => {
    const c = fixtureCorpus();
    expect(c.passages[0].text).toBe(
      '[تجريبي] فقرة اختبار عن الصوم والانقطاع عن الطعام في أيام الأسبوع.',
    );
  });

  it('loads the FAKE corpus the app ships', () => {
    const c = loadCorpus(APP_CONTENT_DIR);
    expect(c.fixture).toBe(true);
    expect(c.passages.length).toBeGreaterThan(0);
    expect(c.passages.every((p) => p.text.length > 0)).toBe(true);
  });

  it('refuses a fixture corpus in production, allows it elsewhere', () => {
    const c = fixtureCorpus();
    expect(() => assertDeployable(c, 'production')).toThrow(CorpusError);
    expect(() => assertDeployable(c, 'development')).not.toThrow();
    expect(() => assertDeployable({ ...c, fixture: false }, 'production')).not.toThrow();
  });

  it('rejects a missing or malformed corpus', () => {
    expect(() => loadCorpus('/nonexistent-dir')).toThrow(CorpusError);
    const dir = mkdtempSync(join(tmpdir(), 'corpus-'));
    writeFileSync(join(dir, 'manifest.json'), '{"schemaVersion":2}');
    expect(() => loadCorpus(dir)).toThrow(CorpusError);
  });

  it('rejects duplicate paragraph ids', () => {
    const dir = mkdtempSync(join(tmpdir(), 'corpus-'));
    mkdirSync(join(dir, 'saints'));
    const manifest = {
      schemaVersion: 1,
      contentVersion: 1,
      bookId: 'b',
      title: 'b',
      saints: [
        { id: 's1', title: 's1', file: 'saints/s1.json' },
        { id: 's2', title: 's2', file: 'saints/s2.json' },
      ],
    };
    const saint = (id: string) => ({
      schemaVersion: 1,
      id,
      sections: [{ id: `sec-${id}`, title: 't', paragraphs: [{ id: 'p-1', kind: 'body', text: 'x' }] }],
    });
    writeFileSync(join(dir, 'manifest.json'), JSON.stringify(manifest));
    writeFileSync(join(dir, 'saints/s1.json'), JSON.stringify(saint('s1')));
    writeFileSync(join(dir, 'saints/s2.json'), JSON.stringify(saint('s2')));
    expect(() => loadCorpus(dir)).toThrow(/Duplicate paragraph/);
  });
});
