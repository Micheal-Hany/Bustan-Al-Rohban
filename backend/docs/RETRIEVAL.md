# Retrieval design (Task 10a decision record)

**Status:** decided for V1 plumbing; to be re-evaluated on the real book in Task 13. Results on the FAKE corpus prove plumbing only, not Arabic retrieval quality.

## Decision: in-memory lexical BM25 with Arabic normalization

| Option | Arabic quality | Citation accuracy | Deployment / cost | Verdict |
|---|---|---|---|---|
| **Lexical (BM25) in memory** | Good for a single, known, small book when normalized (diacritics, alef/ya/ta-marbuta, light article stripping). Misses pure paraphrase. | Exact: a hit is a real paragraph with its ID, page and text. | No database, no embedding provider, no cost, deterministic and testable offline. | **Chosen now** |
| Vector (embeddings) | Handles paraphrase, but quality depends on an external embedding model's Arabic ability, which cannot be judged on FAKE text. | Same (still returns real paragraphs). | Needs an embedding provider or pgvector, indexing job, cost, a second thing to key and secure. | Deferred |
| Hybrid | Best expected recall. | Same. | Both of the above. | Candidate for Task 13 |

Reasons: (1) the corpus is one book (a few thousand paragraphs): the whole index fits in memory and is rebuilt at startup in milliseconds; (2) scope filters (saint, section) are applied **inside** the index walk, so out-of-scope paragraphs are never scored or returned (the SPEC 7.6 requirement that scope is a database filter, not a prompt instruction); (3) the "sufficient evidence" rule needs measurable per-term evidence, which lexical matching gives directly; (4) nothing here persists data (SPEC 7.4: the backend is stateless).

**Revisit in Task 13** with the real book: measure recall on the evaluation questions. If lexical recall is too low on paraphrased questions, add embeddings as a *second candidate generator* behind the same interface (hybrid), keeping the same scope filter and the same evidence rule. PostgreSQL (SPEC 12.4) is then only needed if the index moves out of memory or for answer reports (Task 12a); it never stores chat text.

## Pipeline

1. **Corpus** (`src/sources`): reads the same `manifest.json` + `saints/*.json` the app ships. One paragraph = one passage (chunking by paragraph). Passage text is never modified. A corpus with `"fixture": true` is refused when `NODE_ENV=production`.
2. **Normalization** (`src/retrieval/arabic.ts`): same folding as the app's local search. Light stemming removes only the definite article (with و/ب/ك/ف/ل); a small stop-word list (question words, prepositions, "the book" words) is removed from queries and from the index. Both lists are provisional.
3. **Scope** (`retrieval.service.ts`): `saint_scope` allows one saint (optionally one section); `book_scope` allows the whole book. The scope comes only from the request's `scope` fields. Earlier messages and the wording of the question never widen it; only the last user message is searched.
4. **Saint aliases** (`alias-table.ts`): title and `aliases` from the manifest, matched as whole normalized words, longest first. Shared aliases resolve to all saints (ambiguity is visible). Saint names are removed from the search terms (a name is not evidence).
   - `book_scope`: a named saint's passages get a x1.5 boost; nothing is filtered out.
   - `saint_scope`: if the question names a *different* saint (and not the scoped one), it is refused with `out_of_scope_saint` and `suggestedSaintIds`, so the UI can offer an explicit scope change. If it names the scoped saint too, retrieval stays in scope.
5. **Sufficient evidence** (`evidence.ts`, constants in `EVIDENCE_RULE`): coverage = IDF weight of the question terms found in the passage / IDF weight of all question terms (terms absent from the book still count in the total). Sufficient when the top passage has coverage >= 0.6 and matches >= min(2, #terms) terms, or the top 3 passages together reach >= 0.85 with >= 2 terms. Otherwise the answer is a fixed refusal, with no model call.
6. **Refusal** (`REFUSAL_MESSAGE`): "لم أجد في كتاب بستان الرهبان ما يجيب عن هذا السؤال." with a machine reason: `insufficient_evidence`, `no_searchable_terms`, `out_of_scope_saint`.

## Privacy

Logs carry request id, mode, saint/section id, outcome, hit count and time only. They never contain the question, messages, passages or prompts (tested). Errors never echo input. `conversationId` is accepted for correlation only and ignored. No database, no file writes.

## Known limits (honest list)

- No paraphrase understanding (no embeddings yet).
- Stemming is only the article; plural and verb forms are not unified.
- Thresholds are provisional and untuned until real content exists.
