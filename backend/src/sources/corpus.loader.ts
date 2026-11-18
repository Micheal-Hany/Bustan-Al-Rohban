import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { z } from 'zod';
import { Corpus, Passage, SaintInfo } from './corpus.types';

const idSchema = z.string().min(1).max(100);

const manifestSchema = z.object({
  schemaVersion: z.literal(1),
  contentVersion: z.number().int().min(1),
  bookId: idSchema,
  title: z.string().min(1),
  fixture: z.boolean().optional(),
  saints: z.array(
    z.object({
      id: idSchema,
      title: z.string().min(1),
      aliases: z.array(z.string().min(1)).default([]),
      file: z.string().min(1),
    }),
  ),
});

const saintSchema = z.object({
  schemaVersion: z.literal(1),
  id: idSchema,
  sections: z.array(
    z.object({
      id: idSchema,
      title: z.string(),
      paragraphs: z.array(
        z.object({
          id: idSchema,
          kind: z.enum(['body', 'heading', 'quote', 'note']),
          page: z.number().int().nullable().optional(),
          text: z.string(),
        }),
      ),
    }),
  ),
});

export class CorpusError extends Error {}

/**
 * Loads the book corpus from the same manifest + per-saint JSON files the app
 * ships (docs/CONTENT_SCHEMA.md). One paragraph becomes one passage.
 */
export function loadCorpus(dir: string): Corpus {
  const read = (rel: string): unknown => {
    try {
      return JSON.parse(readFileSync(join(dir, rel), 'utf8'));
    } catch {
      throw new CorpusError(`Cannot read corpus file "${rel}".`);
    }
  };
  const parsed = manifestSchema.safeParse(read('manifest.json'));
  if (!parsed.success) throw new CorpusError('manifest.json is invalid.');
  const manifest = parsed.data;

  const saints: SaintInfo[] = [];
  const passages: Passage[] = [];
  const seenParagraphs = new Set<string>();
  const seenSaints = new Set<string>();

  for (const entry of manifest.saints) {
    if (seenSaints.has(entry.id)) throw new CorpusError(`Duplicate saint id "${entry.id}".`);
    seenSaints.add(entry.id);
    const file = saintSchema.safeParse(read(entry.file));
    if (!file.success) throw new CorpusError(`${entry.file} is invalid.`);
    if (file.data.id !== entry.id) {
      throw new CorpusError(`${entry.file}: id differs from the manifest.`);
    }
    const sectionIds: string[] = [];
    for (const section of file.data.sections) {
      sectionIds.push(section.id);
      for (const p of section.paragraphs) {
        if (seenParagraphs.has(p.id)) {
          throw new CorpusError(`Duplicate paragraph id "${p.id}".`);
        }
        seenParagraphs.add(p.id);
        passages.push({
          paragraphId: p.id,
          bookId: manifest.bookId,
          saintId: entry.id,
          saintTitle: entry.title,
          sectionId: section.id,
          sectionTitle: section.title,
          page: p.page ?? null,
          kind: p.kind,
          text: p.text,
          contentVersion: manifest.contentVersion,
        });
      }
    }
    saints.push({ id: entry.id, title: entry.title, aliases: entry.aliases, sectionIds });
  }

  return {
    bookId: manifest.bookId,
    title: manifest.title,
    contentVersion: manifest.contentVersion,
    fixture: manifest.fixture === true,
    saints,
    passages,
  };
}

/**
 * FAKE fixture content must never reach a production index (ROADMAP,
 * "Important content rule").
 */
export function assertDeployable(corpus: Corpus, nodeEnv: string | undefined): void {
  if (nodeEnv === 'production' && corpus.fixture) {
    throw new CorpusError('Refusing to start: the corpus is FAKE fixture content.');
  }
}
