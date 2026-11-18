export type ChatMode = 'saint_scope' | 'book_scope';

export interface RetrievalScope {
  bookId?: string;
  saintId?: string;
  sectionId?: string;
}

export interface ChatMessageInput {
  role: 'user' | 'assistant';
  text: string;
}

export interface RetrievalRequest {
  mode: ChatMode;
  scope: RetrievalScope;
  messages: ChatMessageInput[];
}

export interface RetrievedPassage {
  paragraphId: string;
  saintId: string;
  saintTitle: string;
  sectionId: string;
  sectionTitle: string;
  page: number | null;
  kind: string;
  text: string;
  score: number;
}

export type RefusalReason =
  | 'insufficient_evidence'
  | 'no_searchable_terms'
  | 'out_of_scope_saint';

export interface EvidenceDiagnostics {
  sufficient: boolean;
  queryTerms: number;
  topCoverage: number;
  unionCoverage: number;
  topMatched: number;
}

export type RetrievalResult =
  | {
      status: 'ok';
      passages: RetrievedPassage[];
      /** Saints named in the question (for the UI; never widens the scope). */
      mentionedSaintIds: string[];
      evidence: EvidenceDiagnostics;
    }
  | {
      status: 'refused';
      reason: RefusalReason;
      message: string;
      /** For out_of_scope_saint: the saints the user asked about. */
      suggestedSaintIds?: string[];
      evidence?: EvidenceDiagnostics;
    };
