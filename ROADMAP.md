# Bustan Al-Rohban --- Implementation Roadmap

**Project:** Bustan Al-Rohban (بستان الرهبان)\
**Website:** https://coptic-treasures.com/\
**Document:** `ROADMAP.md` v1.1\
**Source of truth:** `SPEC.md` v1.2\
**Status:** Approved plan. Implementation has **not** started. Waiting for the owner's **GO**.

| Version | Date | Summary |
|---|---|---|
| 1.0 | 2026-11-15 | Original 13-task plan. |
| 1.1 | 2026-11-15 | Added TTS spike S1, split Task 10 into 10a-10d, split Task 12 into 12a/12b, added Task 13 (real content import), scope-isolation and abuse-protection tests, early AI evaluation set, backup exclusion, report-answer hook, FTS exception, GO precondition. |

---

## 1. Project objective

Build an Arabic-first Flutter application for reading and studying Bustan Al-Rohban, with:

- An offline digital library and reader.
- Arabic local search.
- Bookmarks and reading progress.
- Reading preferences.
- Prepared, reviewed insights.
- Arabic text-to-speech.
- An AI assistant grounded exclusively in Bustan Al-Rohban.
- Local conversation history.
- OpenAI and Google Gemini provider support through a backend abstraction.

Priorities: content accuracy, offline functionality, Arabic RTL usability, preservation of the original book text.

## 2. Approved decisions

| Decision | Final choice |
|---|---|
| AI providers | OpenAI and Google Gemini (both implemented) |
| RAG scope | Bustan Al-Rohban only |
| Chat history | Local SQLite/Drift, excluded from Android backups |
| Backend chat storage | Stateless; no persistent conversation storage |
| Chat delivery | Non-streaming in V1 (citation validation needs the full answer) |
| User accounts | Not required |
| API keys | Backend only; never inside Flutter |
| Anonymous abuse protection | Rate limits + Play Integrity + global daily spend cap with kill switch |
| Temporary content | Three clearly labeled FAKE saints, 2-3 sections each |
| Real book content | Supplied by the owner as extracted text files (authoring format in `docs/CONTENT_SCHEMA.md`) |
| PDF extraction/OCR | Not performed by the implementation team |
| Rights gate | Owner-confirmed; resolved |
| AI answer / theological review | Owner reviews all AI answers and theological content |
| Content schema | Must be approved by the owner **before** the real files are prepared |

### Important content rule

Until the actual book text is supplied, development and testing use clearly labeled FAKE fixtures. Never invent, reconstruct, or present fake content as authentic book content. FAKE content must never be in a release build or in the production backend index.

The AI must refuse when retrieved book evidence is insufficient. It must not use general model knowledge as a substitute.

## 3. Architecture and implementation constraints

### Flutter application

- Flutter and Dart. BLoC/Cubit where state management is needed. Drift/SQLite for local persistence.
- Arabic UI with RTL support throughout.
- Stable IDs for saints, sections, paragraphs, bookmarks, progress, conversations, and messages.
- Keep the architecture simple. No unnecessary layers or abstractions.
- Original book text stays untouched. Editorial additions are visually distinguishable.

### Content management

- Structured, validated content schema (`docs/CONTENT_SCHEMA.md`).
- Stable identifiers and ordering; page references and paragraph anchors preserved.
- Validate duplicate IDs, missing fields, invalid references, malformed content.
- Normalized search representation when required, never changing displayed text.

### Offline requirements

Must work offline: library browsing, reading, local search, bookmarks, reading progress, reading preferences, existing conversation history. New AI requests and answer reports require internet.

### AI backend

- Stateless chat API; book-only RAG; retrieval filters enforced server-side.
- OpenAI and Gemini adapters behind a provider abstraction; keys on the backend.
- Validate citations and verbatim quotations against retrieved passages.
- Refuse unsupported questions.
- Track provider, model, token usage, estimated cost.
- Rate limits, app attestation, global daily spend cap.
- No persistent conversation content on the backend.

### AI content safety

- Grounded in retrieved book passages; invalid citations rejected; unsupported answers refused.
- Ascetic practices are reported as history, never as personal, medical, or mental-health advice (SPEC §6.4).
- Owner reviews all AI and theological content.

---

# 4. Implementation roadmap

Each task is completed, tested, reported, and approved before the next one starts.

**Order:** 0, 1, 2, **S1**, 3, 4, 5, 6, 7, 8, 9, 10a, 10b, 10c, 10d, 11, 12a, 12b, 13.

Every task lists two verification paths: **A. Automated** and **B. Manual**.

## Phase 0 --- Foundation

### Task 0 --- Project setup

**Scope:** Flutter project, app structure/bootstrap, Arabic RTL theme, Arabic font, routing, BLoC/Cubit and required dependencies, placeholder screens.\
**Dependencies:** None.

**A. Automated**
```bash
flutter analyze
flutter test test/app/app_boot_test.dart
flutter test test/app/rtl_smoke_test.dart
```
Expected: boot test passes; initial route works; RTL direction correct; theme initializes.

**B. Manual**
1. Install and launch the app.
2. Confirm the home screen opens.
3. Confirm Arabic text displays RTL.
4. Navigate between placeholder screens.
5. Confirm startup does not require internet.

### Task 1 --- Content schema, loader, validator, FAKE fixture

**Scope:** Implement the schema in `docs/CONTENT_SCHEMA.md` (owner-approved 2026-11-15): manifest plus per-saint files, stable IDs and ordering, page metadata, content versioning; the **authoring-format converter** (owner text files to JSON); loader and validator with useful errors; three FAKE saints with 2-3 sections each.\
**Dependencies:** Task 0, and **owner approval of `docs/CONTENT_SCHEMA.md`**.

**A. Automated**
```bash
flutter analyze
flutter test test/core/content/
flutter test
```
Expected: valid content loads; ordering preserved; duplicate IDs rejected; missing fields and invalid references detected; malformed JSON gives understandable errors; authoring-format converter round-trips; FAKE records are labeled `fixture: true`.

**B. Manual**
1. Open the content preview.
2. Inspect all three FAKE saints.
3. Open their sections.
4. Confirm stable ordering and FAKE labels.
5. Load an invalid fixture and inspect its error.

---

## Phase 1 --- Offline library

### Task 2 --- Library and navigation

**Scope:** Library home, book overview, saints list, sections list, navigation, loading/empty/error states. Content loaded per saint on demand.\
**Dependencies:** Tasks 0-1.

**A. Automated**
```bash
flutter analyze
flutter test test/features/library/
flutter test
```
Expected: repository ordering; navigation; list rendering; empty states.

**B. Manual**
1. Open the library.
2. Select a FAKE saint.
3. Open one of its sections.
4. Navigate back.
5. Repeat with internet disabled.

### Spike S1 --- TTS feasibility (before the reader)

**Purpose:** Learn early whether Arabic TTS is viable on target devices. Throwaway proof of concept, kept in `spikes/tts/` (or a branch), not production code.\
**Scope:** Detect Arabic voice availability; test offline synthesis; test unvowelled-text pronunciation; test position callbacks with `flutter_tts`; test chunk sequencing; note what background playback would need (Android foreground-service type rules).\
**Dependencies:** Task 0.

**A. Automated**
```bash
flutter analyze
flutter test spikes/tts/   # chunk-splitter unit tests only
```
Expected: chunk splitter preserves order and loses no text.

**B. Manual (on real devices)**
1. List the Arabic voices/engines available.
2. Play a long FAKE Arabic passage in airplane mode.
3. Pause, resume, change speed.
4. Check pronunciation of unvowelled text.
5. Write findings (devices, voices, limits) into `docs/TTS_SPIKE.md`; the owner decides the background-audio question (SPEC §19 #8).

### Task 3 --- Arabic reader

**Scope:** Reading screen, original text rendering, page references, text-size controls, stable paragraph anchors, visually distinct editorial additions, long-text handling.\
**Dependencies:** Tasks 1-2.

**A. Automated**
```bash
flutter analyze
flutter test test/features/reader/
flutter test
```
Expected: paragraph rendering; page mapping; long Arabic text; RTL; no clipping; original text unchanged.

**B. Manual**
1. Open a section.
2. Scroll through its Arabic content.
3. Change text size.
4. Inspect page references.
5. Confirm editorial additions look different from original text.

### Task 4 --- Arabic local search

**Scope:** Offline search with Arabic normalization (diacritics, alef variants, ya/alef maqsura, ta marbuta), ranking, empty states. Uses a derived SQLite FTS index with a normalized column: this is the **allowed exception** to "no duplicate content in SQLite" (SPEC §11.2). Displayed text always comes from the original JSON.\
**Dependencies:** Tasks 1-2.

**A. Automated**
```bash
flutter analyze
flutter test test/core/search/
flutter test test/features/search/
flutter test
```
Expected: normalization tests; equivalent spellings match; ranking; empty states; normalization never alters displayed text.

**B. Manual**
1. Disable internet.
2. Search an Arabic keyword.
3. Repeat without diacritics.
4. Try equivalent alef/ya spellings.
5. Open a result and verify its source location.

### Task 5 --- Bookmarks and reading progress

**Scope:** Drift persistence; bookmark create/delete; references by **paragraph ID plus offset**; resume reading; migrations where necessary.\
**Dependencies:** Tasks 0, 1, 3.

**A. Automated**
```bash
flutter analyze
flutter test test/features/bookmarks/
flutter test test/features/reader/progress/
flutter test
```
Expected: bookmark CRUD; progress persists; position restores; relationships and migrations work; references survive re-ordering of fixture content.

**B. Manual**
1. Bookmark a paragraph.
2. Restart the app.
3. Open the bookmarks screen.
4. Resume reading.
5. Remove the bookmark and verify it persists.

### Task 6 --- Reading preferences

**Scope:** Persist font size and other reading preferences; sensible defaults; restore after restart.\
**Dependencies:** Tasks 0, 3.

**A. Automated**
```bash
flutter analyze
flutter test test/features/settings/
flutter test
```
Expected: defaults; persistence; reader reflects settings.

**B. Manual**
1. Open settings.
2. Change font size.
3. Return to the reader and confirm the change.
4. Restart the app.
5. Confirm the preference persisted.

---

## Phase 2 --- Reading experience

### Task 7 --- Prepared insights

**Scope:** Summary, key points, spiritual lessons, relationships to paragraph IDs, review status, clear visual distinction from original text. FAKE insights only until the owner approves real ones.\
**Dependencies:** Tasks 1, 3.

**A. Automated**
```bash
flutter analyze
flutter test test/features/insights/
flutter test
```
Expected: parsing; relationships valid; review status handled (unapproved insights are not shown in release mode); distinction in presentation.

**B. Manual**
1. Open a FAKE saint.
2. Open its insights.
3. Inspect summary and key points.
4. Switch between insights and original text.
5. Confirm the visual distinction.

### Task 8 --- Arabic text-to-speech (production)

**Scope:** Play/pause/resume/stop, speed, chunk sequencing, position where supported, Arabic voice checks, clear missing-voice state. Built on the findings of Spike S1. Offline speech is advertised only when a compatible offline Arabic voice exists. Background playback only if S1 and the owner's decision allow it, after validating Android service behavior.\
**Dependencies:** Tasks 0, 3, S1.

**A. Automated**
```bash
flutter analyze
flutter test test/features/audio/
flutter test
```
Expected: chunk ordering; state transitions; pause/resume; error handling.

**B. Manual**
1. Open a section.
2. Start playback.
3. Pause and resume.
4. Change speed.
5. Test offline playback and the missing-Arabic-voice state.

---

## Phase 3 --- AI assistant

### Task 9 --- Local chat history

**Scope:** Drift conversation/message tables; stable conversation IDs; user/assistant roles; ordering; titles derived locally from the first question; delete one; clear all; reopen and continue; **Android backup exclusion for chat history**. Old conversations readable offline; sending needs internet.\
**Dependencies:** Tasks 0, 1.

**A. Automated**
```bash
flutter analyze
flutter test test/features/ai_chat/data/
flutter test test/features/ai_chat/history/
flutter test
```
Expected: CRUD; message ordering; cascade delete; data survives restart; offline reading of old conversations; backup rules file excludes the chat database (checked by a test that parses the rules XML).

**B. Manual**
1. Create a conversation.
2. Add test messages.
3. Restart the app.
4. Reopen the conversation.
5. Delete it and verify it disappears.

### Task 10a --- Backend skeleton, retrieval, refusal

**Scope:** NestJS modular monolith; health endpoint; book-only corpus loader (FAKE fixture only for now); **retrieval technology decision** (document why: lexical vs vector vs hybrid for Arabic); chunking by paragraph; saint alias table; scope filters applied in the query; measurable "sufficient evidence" rule; refusal response; no persistence. Retrieval quality on FAKE data proves plumbing only.\
**Dependencies:** Tasks 1, 9.

**A. Automated**
```bash
cd backend
npm test -- --runInBand
npm run lint
```
Expected: retrieval returns only book content; **saint-scope isolation** (never returns another saint's passages, even if the prompt or earlier messages ask); alias resolution; insufficient evidence leads to refusal; no conversation rows written.

**B. Manual**
1. Start the local backend.
2. Query a FAKE saint with `saint_scope`; inspect passages returned.
3. Query naming a different saint while scoped; confirm no other-saint passages.
4. Ask something unsupported; confirm refusal.
5. Inspect logs; confirm no message text.

### Task 10b --- Citations, structured answers, evaluation set

**Scope:** Structured response schema; citation ID validation against retrieved passages; **verbatim-quotation validation**; non-streaming decision recorded; system policy including SPEC §6.2-6.4 (ascetic-practice handling, pastoral referral); prompt-injection handling (user text, source text, prior messages); **AI evaluation set created now** with the thresholds in SPEC §6.6 (owner approves expected behavior); a provider-agnostic fake LLM used to run the set.\
**Dependencies:** Task 10a.

**A. Automated**
```bash
cd backend
npm test -- --runInBand
npm run lint
npm run eval   # evaluation set against the fake LLM
```
Expected: invalid citations rejected; non-substring quotes rejected; refusal cases pass; injection cases pass; evaluation harness runs and reports per-category results.

**B. Manual**
1. Review the evaluation set file; approve or correct expected behaviors.
2. Run `npm run eval` and read the report.
3. Send a request with a forged citation ID in a mock response; confirm rejection.
4. Send an ascetic-practice "should I do this" question; confirm the safe response.
5. Confirm no prompt text is stored.

### Task 10c --- Provider adapters, usage, cost

**Scope:** Provider abstraction; **OpenAI adapter** and **Gemini adapter**; provider/model chosen by backend configuration; timeout and error mapping; usage extraction; versioned pricing config; estimated cost (marked estimated/unavailable when usage is missing); record the actual provider/model per request. Mocked provider APIs in tests.\
**Dependencies:** Task 10b.

**A. Automated**
```bash
cd backend
npm test -- --runInBand
npm run lint
```
Expected: both adapters pass the same contract tests with mocks; config switch changes provider without code change; cost math correct including missing-usage and pricing-version cases; timeouts and provider errors mapped.

**B. Manual**
1. Set provider to OpenAI in config; send a request (test key, local only).
2. Switch to Gemini in config; repeat.
3. Inspect the usage/cost log line.
4. Confirm no key appears in responses or logs.
5. Confirm the Flutter project contains no provider keys (`grep`).

### Task 10d --- Abuse protection and spending controls

**Scope:** Per-IP and per-installation rate limits; Play Integrity attestation verification (with a documented test mode); request size and message-count limits; **global daily spend cap with kill switch**; privacy-safe logging test; answer-report endpoint stub storing no history (completed in Task 12a).\
**Dependencies:** Task 10c.

**A. Automated**
```bash
cd backend
npm test -- --runInBand
npm run lint
cd ..
flutter analyze
flutter test
```
Expected: rate limit trips; invalid attestation rejected; spend cap triggers "temporarily unavailable"; logs and DB contain no chat text; Flutter regression green.

**B. Manual**
1. Send requests past the limit; confirm the limit response.
2. Lower the daily cap in config; confirm the kill switch.
3. Send a request without attestation; confirm rejection.
4. Inspect logs and DB for message text (none expected).
5. Restore the config.

### Task 11 --- Flutter AI chat UI

**Scope:** Arabic RTL chat; conversation history; loading, timeout, error, offline states; source references and citations; structured answer rendering; context-aware continuation with bounded history; clear **"answers from Bustan Al-Rohban only"** indicator; explicit scope-change UI; **"report this answer" entry point** (wired to the endpoint in Task 12a); preserve typed text when offline.\
**Dependencies:** Tasks 9, 10a-10d.

**A. Automated**
```bash
flutter analyze
flutter test test/features/ai_chat/presentation/
flutter test
```
Expected: all UI states; citations render; RTL; context trimming keeps recent turns and scope; history readable offline.

**B. Manual**
1. Open chat from a FAKE saint.
2. Send a question; inspect response and citations.
3. Disable internet and send another; confirm the offline state and kept text.
4. Reopen the conversation offline and inspect history.
5. Tap "report this answer" and confirm the confirmation screen shows exactly what will be sent.

---

## Phase 4 --- Release readiness

### Task 12a --- Privacy, reporting, disclosures

**Scope:** Privacy notice (local history, transmission to backend and AI provider, backup exclusion, uninstall behavior); report-answer end to end (no conversation history stored); Google Play Data Safety and AI-content disclosure preparation; crash-reporting choice and its privacy check.\
**Dependencies:** Tasks 9-11.

**A. Automated**
```bash
flutter analyze
flutter test
cd backend && npm test -- --runInBand && npm run lint
```
Expected: report stored without history; privacy notice screen present; no analytics/crash SDK captures chat text (dependency and config check).

**B. Manual**
1. Read the privacy notice for accuracy against actual behavior.
2. Report an answer; inspect the stored record.
3. Review the Data Safety draft against the app.
4. Confirm crash reporting settings.
5. Owner approves the wording.

### Task 12b --- Device, accessibility, and release checks

**Scope:** Android compatibility matrix; TalkBack; Arabic font licence verification; dark mode; final online/offline verification matrix; release build.\
**Dependencies:** Task 12a.

**A. Automated**
```bash
flutter analyze
flutter test
flutter build apk --release
```
Expected: regressions pass; release APK builds; no provider secrets in the bundle (scan).

**B. Manual**
1. Install the release APK on the matrix devices.
2. Test offline reading and search.
3. Test online AI chat.
4. Test TalkBack and dark mode.
5. Fill in the verification matrix and the owner signs it off.

### Task 13 --- Real content import and re-validation

**Scope:** Import the owner's extracted text files; run the Task 1 validator and produce a **content report** (broken IDs, ordering, missing/uncertain pages, empty paragraphs, suspicious characters); owner corrects the source files; ship the real JSON; index the same corpus on the backend; **re-run** search tests with real Arabic, retrieval-quality checks, and the evaluation set; measure content size and decide performance budgets; remove FAKE fixtures from release builds and from the production index; verify local and server content versions match; reviewed real insights (owner-approved) imported.\
**Dependencies:** Tasks 1-12b and the owner's real text files.

**A. Automated**
```bash
flutter analyze
flutter test
flutter test test/core/content/ --name "real content"
cd backend && npm test -- --runInBand && npm run lint && npm run eval
```
Expected: real content validates with zero errors; version check passes; evaluation thresholds in SPEC §6.6 met; no FAKE content in the release asset list.

**B. Manual**
1. Read the content report and spot-check pages against the book.
2. Browse several real saints and sections.
3. Search with and without diacritics on real text.
4. Ask book questions in both scopes and review citations against the book.
5. Owner approves the evaluation results and the real insights.

---

# 5. Mandatory development loop

Applies to every task without exception.

1. Write unit tests.
2. Write widget tests.
3. Implement the feature.
4. Run `flutter analyze`.
5. Run `flutter test`.
6. Run the task-specific backend tests when applicable.
7. Fix all failures.
8. Repeat until the required checks are green.
9. Report the completed work.
10. Provide automated and manual verification results.
11. Stop and wait for the owner's explicit approval.

**Do not begin the next task until the owner says "approved".**

## 6. Required report after every task

- Task number and name.
- What changed.
- Important implementation decisions.
- Files created or modified.
- Automated tests executed.
- Exact test results.
- Known limitations.
- Manual verification steps (3-5) with expected result for each.

Do not claim a test passed unless it was actually executed successfully.

## 7. Conflict-resolution rule

`SPEC.md` is the source of truth. If a requirement conflicts with `SPEC.md` or an existing decision:

1. Stop the affected task.
2. Explain the conflict.
3. Identify the competing requirements.
4. Ask for clarification.
5. Do not silently change the specification.

Do not add architecture, duplicate content storage, or new dependencies without a requirement.

## 8. Current implementation status

| Phase | Tasks | Status |
|---|---|---|
| Planning | SPEC v1.2, ROADMAP v1.1, content schema draft | Done; content schema **approved 2026-11-15** |
| Foundation | 0-1 | Not started |
| Offline library | 2, S1, 3-6 | Not started |
| Reading experience | 7-8 | Not started |
| AI assistant | 9, 10a-10d, 11 | Not started |
| Release readiness | 12a, 12b | Not started |
| Real content | 13 | Not started; waiting for owner's text files |

**No application code has been written.**

## 9. Start authorization

Approval of the plan is not authorization to start coding.

Reply **GO** only after:

1. The repository exists and contains `SPEC.md`, `ROADMAP.md`, and `docs/CONTENT_SCHEMA.md`.
2. The owner has approved `docs/CONTENT_SCHEMA.md` (or listed changes).

If any are missing, request them instead of assuming their contents.

After GO, begin with **Task 0 only**. Do not proceed to Task 1 until Task 0 is implemented, tested, reported, and approved.
