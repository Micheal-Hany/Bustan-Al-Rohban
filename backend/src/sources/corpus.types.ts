/** One retrievable unit: exactly one book paragraph, with its metadata. */
export interface Passage {
  /** Stable paragraph id from the content files (for example "p-000001"). */
  paragraphId: string;
  bookId: string;
  saintId: string;
  saintTitle: string;
  sectionId: string;
  sectionTitle: string;
  /** Printed page number, or null when unknown. */
  page: number | null;
  kind: 'body' | 'heading' | 'quote' | 'note';
  /** The original text, exactly as in the book files (never normalized). */
  text: string;
  contentVersion: number;
}

export interface SaintInfo {
  id: string;
  title: string;
  aliases: string[];
  sectionIds: string[];
}

export interface Corpus {
  bookId: string;
  title: string;
  contentVersion: number;
  /** True for the FAKE fixture corpus. Never allowed in production. */
  fixture: boolean;
  saints: SaintInfo[];
  passages: Passage[];
}
