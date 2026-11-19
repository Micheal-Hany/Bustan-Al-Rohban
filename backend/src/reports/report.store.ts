import { appendFile, mkdir, readFile } from 'node:fs/promises';
import { dirname } from 'node:path';

/**
 * One stored answer report (SPEC 7.8). This is ALL that is kept: no
 * conversation history, no installation id, no IP address, no attestation
 * token. Reports are for owner review and are never used for training.
 */
export interface StoredReport {
  id: string;
  receivedAt: string;
  reason: string;
  note?: string;
  answerText: string;
  question: string;
  citedParagraphIds: string[];
  contentVersion: number;
  provider: string;
  model: string;
}

export interface ReportStore {
  add(report: StoredReport): Promise<void>;
  list(): Promise<StoredReport[]>;
}
export const REPORT_STORE = 'REPORT_STORE';

/** Memory only: tests. */
export class InMemoryReportStore implements ReportStore {
  readonly items: StoredReport[] = [];

  add(report: StoredReport): Promise<void> {
    this.items.push(report);
    return Promise.resolve();
  }

  list(): Promise<StoredReport[]> {
    return Promise.resolve([...this.items]);
  }
}

/**
 * Append-only JSON-lines file (one report per line). A simple store for a
 * single-instance deployment with a persistent disk; PostgreSQL (SPEC 12.4)
 * can replace it behind the same interface.
 */
export class FileReportStore implements ReportStore {
  constructor(private readonly file: string) {}

  async add(report: StoredReport): Promise<void> {
    await mkdir(dirname(this.file), { recursive: true });
    await appendFile(this.file, JSON.stringify(report) + '\n', { encoding: 'utf8', mode: 0o600 });
  }

  async list(): Promise<StoredReport[]> {
    let text: string;
    try {
      text = await readFile(this.file, 'utf8');
    } catch (e) {
      if ((e as NodeJS.ErrnoException).code === 'ENOENT') return [];
      throw e;
    }
    return text
      .split('\n')
      .filter((l) => l.trim() !== '')
      .map((l) => JSON.parse(l) as StoredReport);
  }
}
