# AI policy and validation (Task 10b)

Source of truth: SPEC §6.2–6.6, §7.6, §12.3. Status: **owner review required**
for every Arabic string marked below.

## Request flow (`POST /v1/chat`, stateless, non-streaming)

1. Parse and bound the request (same limits as `/v1/retrieve`).
2. Scope check (unknown saint/section → 400).
3. **Safety pre-check** (`theological-policy/safety.ts`): self-harm, personal
   medical, personal ascetic "should I do this", confession/sacrament requests
   get a fixed Arabic response with a referral (confession father /
   professional / emergency). **The model is not called.** Historical
   questions ("how did the saint fast?") are not matched.
4. Retrieval + sufficient-evidence rule (10a). Failure → fixed refusal, no model call.
5. Model call with the system policy + tagged data blocks (`system-prompt.ts`).
6. **Validation** (`chat/validation.ts`): schema; every block cites ≥1 id; every
   id is one of the passages retrieved *for this request*; every `quotation`
   is a verbatim substring (whitespace-insensitive only) of a passage it cites;
   no absolution / clergy impersonation / "official church statement" phrases.
7. One corrective retry; if still invalid → fixed "could not prepare a reliable
   answer" message. A model `not_in_book` → fixed refusal.
8. Sensitive topics (fasting, confession, repentance, …) get a pastoral note.

## Decisions

- **Non-streaming.** Validation needs the complete output; streaming unvalidated
  text would let an invented quote reach the screen. Revisit only with a
  design that validates before display.
- **Prompt injection.** Nothing user- or book-derived enters the system policy.
  Question, earlier messages and passages sit in tagged blocks marked
  untrusted, with `<`/`>` escaped so data cannot close its block. The real
  protection is code: scope is fixed by the request fields, citations/quotes are
  checked, forbidden phrases are rejected.
- **No storage.** No prompt, question or answer is logged; log fields are ids,
  outcome, attempts, timing.
- **Production.** The fake model is refused in production; real adapters (OpenAI,
  Gemini) arrive in 10c.

## Owner review list

`SAFETY_RESPONSES`, `PASTORAL_NOTE`, `UNVALIDATED_MESSAGE`, the lexicons in
`safety.ts`, `FORBIDDEN_PHRASES`, `SYSTEM_PROMPT`, `eval/cases.json` expected
behaviour, and `eval/thresholds.json` (set `approvedByOwner: true` when agreed).

## Evaluation (`npm run eval`)

`eval/cases.json`: 40 cases over the 13 SPEC §6.6 categories, on a FAKE corpus
(`eval/corpus`, including a source paragraph that contains an injection). Run
with the scripted fake model, so it proves **pipeline enforcement**, not model
quality; `scriptedOnly` cases (false premise, doctrine) need real-model judgement
and are re-run against OpenAI/Gemini in 10c. Release-blocking thresholds are
SPEC §6.6; non-critical thresholds (0.9 proposed) await owner approval.

## Providers, usage and cost (Task 10c)

- Adapters: `providers/openai.provider.ts` (Chat Completions, JSON mode) and
  `providers/gemini.provider.ts` (generateContent, JSON mime type), plain `fetch`,
  no SDK. Both pass the same contract tests with mocked HTTP.
- Chosen by `LLM_PROVIDER` / `LLM_MODEL` (env). Missing model or key fails at startup.
- The key is sent only in a request header (never URL, body, response or log).
- Errors: timeout -> 504 `provider_timeout`; rate limit -> 503 `provider_busy`;
  anything else -> 502 `provider_error`. Provider bodies are never forwarded.
- Usage is summed over attempts (a retry costs money). If any call omits usage the
  total is unknown and cost is `unavailable` (`usage_missing`).
- Cost = tokens x `config/pricing.json` (versioned, USD per 1M tokens). An unpriced
  model gives `unavailable` (`no_pricing`), never a guess. The shipped file is
  EMPTY: **owner must fill real prices and bump `version`.** Cost is always an estimate.
- Each request logs provider, model, tokens, cost, status, pricing version (no text);
  the response `meta` carries the same, so the actual model used is always recorded.
- Real-model evaluation (scriptedOnly cases) is run by the owner with real keys once
  prices/models are chosen; the harness still uses the fake model by default.
