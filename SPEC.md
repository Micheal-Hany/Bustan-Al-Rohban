# Bustan Al-Rohban --- Project Specification

**Document:** `SPEC.md`\
**Version:** 1.2\
**Status:** Updated baseline. Aligned with `ROADMAP.md` v1.1 (book-only RAG, owner-supplied text, owner review).\
**Platform:** Flutter Android application (initial target)\
**Primary language:** Arabic\
**Product approach:** Offline-first library with an online, book-only AI assistant

**Changelog**

| Version | Date | Summary |
|---|---|---|
| 1.1 | 2026-11-15 | Local chat history, OpenAI/Gemini adapters, scoped RAG. |
| 1.2 | 2026-11-15 | RAG restricted to Bustan Al-Rohban only; owner-supplied extracted text (no PDF/OCR by the team); rights confirmed by owner; owner reviews AI/theological content; anonymous-abuse protection; report-answer; acceptance criteria cleaned up; open-decision list reconciled. See §20 and §23. |

------------------------------------------------------------------------

## 1. Purpose of This Document

This document is the product and technical source of truth for the first
release of the Bustan Al-Rohban application.

It defines:

-   What the application is intended to do.
-   Which features are included in Version 1.
-   How the book content is organized and displayed.
-   Which capabilities work offline and which require internet access.
-   How the AI assistant must answer questions while respecting the
    doctrine and tradition of the Coptic Orthodox Church.
-   The proposed application architecture, data model, backend
    responsibilities, and quality requirements.
-   Acceptance criteria that can be used to decide whether a feature is
    complete.

If an implementation decision conflicts with this document, the conflict
must be raised and resolved before implementation. Do not silently
change product requirements.

The task-by-task delivery plan lives in `ROADMAP.md`. The content file
format lives in `docs/CONTENT_SCHEMA.md`.

------------------------------------------------------------------------

## 2. Product Vision

Build a reliable, easy-to-use digital Orthodox Christian reading and
learning experience, starting with **Bustan Al-Rohban**.

The first release must combine:

1.  A structured digital edition of the book.
2.  Offline reading and local search.
3.  Offline text-to-speech, where a suitable Arabic device voice is
    available.
4.  Prepared summaries, key points, and spiritual lessons.
5.  An online AI chat that answers questions **using only the content of
    Bustan Al-Rohban**, with provider-independent OpenAI/Gemini
    integration, strict retrieval scope, and device-only conversation
    history.

The application must not be treated as merely a PDF viewer. The book
should be represented as structured content that users can browse,
search, listen to, and ask questions about.

### 2.1 Product principles

-   **Faithfulness:** Preserve the original source text and its meaning.
-   **Orthodox alignment:** The AI assistant must not teach or recommend
    beliefs that conflict with the doctrine and received tradition of
    the Coptic Orthodox Church.
-   **Source transparency:** Distinguish quotations from the book,
    summaries, and cautious inferences.
-   **Offline-first:** Core reading features must not depend on a
    server.
-   **Privacy:** Do not collect unnecessary personal data.
-   **Simplicity:** Build only the architecture needed for the
    requirements; avoid premature complexity.
-   **Extensibility:** Keep the content model capable of supporting more
    books later.

------------------------------------------------------------------------

## 3. Scope

### 3.1 Version 1 --- Included

  -----------------------------------------------------------------------
  Capability              Version 1 requirement   Connectivity
  ----------------------- ----------------------- -----------------------
  Browse the book         Browse saints,          Offline
                          sections, and           
                          subsections             

  Read original text      Display the prepared    Offline
                          text with source page   
                          references              

  Local search            Search the installed    Offline
                          book content            

  Bookmarks               Save and remove         Offline
                          bookmarks               

  Reading progress        Save and restore the    Offline
                          last reading position   

  Text-to-speech          Read content aloud      Offline, subject to
                          using the device's      installed voice
                          Arabic TTS engine       availability

  Reading preferences     Text size and other     Offline
                          basic reading settings  

  Prepared insights       Show reviewed           Offline
                          summaries, key points,  
                          and spiritual lessons   

  AI chat                 Ask questions about the Online
                          book and receive        
                          book-grounded answers   

  Chat context            Allow the user to ask   Online
                          about the currently     
                          open saint or section   

  Source references       Show book/page/section  Online
                          references used by the  
                          AI                      

  Local chat history      Store, list, reopen,    Offline to read;
                          and delete                 sending requires
                          conversations on the    internet
                          device only             

  Report answer           Let the user flag a bad Online
                          AI answer               

  Error and offline       Explain when chat       Offline UI; chat
  states                  cannot connect while    requires internet
                          preserving local        
                          features                
  -----------------------------------------------------------------------

### 3.2 Explicitly out of scope for Version 1

Unless separately approved, do not include:

-   User accounts or social profiles.
-   Public user-to-user chat.
-   Community posts, comments, or discussion groups.
-   Payments, subscriptions, or advertisements.
-   Downloading additional books from a server.
-   Synchronizing bookmarks between devices.
-   Generating and storing audio files for every chapter.
-   An unrestricted general-purpose chatbot.
-   **AI retrieval from any source other than Bustan Al-Rohban** (other
    books, church documents, patristic writings, websites).
-   AI-generated doctrinal rulings, confession guidance, or personal
    spiritual direction.
-   User-facing AI provider/model selection in Version 1. Provider and
    model selection are controlled by the project administrator through
    backend configuration.
-   Cloud chat-history synchronization or permanent server-side storage
    of conversation messages.

### 3.3 Future possibilities

The architecture may later support:

-   A multi-book Christian library.
-   Additional approved Orthodox books and patristic sources for AI
    retrieval (requires a new approved decision, source review, and a
    SPEC change).
-   Content updates and book downloads.
-   User accounts and cross-device synchronization.
-   Additional platforms.
-   More advanced audio features.
-   A reviewed content-management system.

These possibilities must not delay the first release.

------------------------------------------------------------------------

## 4. Users and Main Use Cases

### 4.1 Main user

An Arabic-speaking reader who wants to read and understand Bustan
Al-Rohban, listen to its content, search it, and ask questions related
to its material from an Orthodox perspective.

### 4.2 Main user journeys

**Journey A --- Read a saint's life**

1.  Open the application.
2.  Open Bustan Al-Rohban.
3.  Browse the list of saints.
4.  Select a saint.
5.  Select a section.
6.  Read the original text.
7.  See the source page reference.
8.  Optionally bookmark the section.

**Journey B --- Search while offline**

1.  Open search.
2.  Enter a name, phrase, or keyword.
3.  See matching saints and content sections.
4.  Open a result.
5.  Read it without internet access.

**Journey C --- Listen**

1.  Open a content section.
2.  Press Play.
3.  The application sends the text to the local TTS engine.
4.  The user can pause, resume, stop, and change the reading speed.
5.  The application saves the reading position where technically
    supported.

**Journey D --- Use prepared insights**

1.  Open a saint or section.
2.  Select Summary, Key Points, or Spiritual Lessons.
3.  Read the reviewed content offline.
4.  Navigate back to the original text.

**Journey E --- Ask the AI assistant**

1.  Open the AI chat from the application or from a saint/section.
2.  Ask a question in Arabic.
3.  The application sends the question and relevant context to the
    backend.
4.  The backend retrieves relevant passages from Bustan Al-Rohban only.
5.  The AI generates an answer grounded in those passages.
6.  The response displays references.
7.  If the book does not support a reliable answer, the assistant says
    so instead of guessing.
8.  The user can later reopen a locally saved conversation and continue
    it; the app sends the necessary prior messages with the new request,
    while keeping the saved history on the device only.
9.  The user can report a bad answer.

------------------------------------------------------------------------

## 5. Content and Book Structure

### 5.0 Source of the content

-   The book text is **supplied by the project owner as extracted text
    files** that follow `docs/CONTENT_SCHEMA.md` (authoring format).
-   The implementation team **does not** perform PDF extraction or OCR.
-   The PDF in the project (`بستان الرهبان - الأنبا إبيفانيوس ...pdf`)
    yielded no extractable text in an automated check (only a repeating
    website watermark). It is a reference copy only, not a pipeline
    input.
-   Until the owner's files arrive, development and tests use clearly
    labeled **FAKE** fixtures (three saints, 2-3 sections each). FAKE
    content must never be presented as real book content, shipped in a
    release build, or indexed for the production backend.
-   The owner reviews the text, page mapping, and all editorial
    additions.

### 5.1 Content hierarchy

The content model must not assume that every future book has exactly the
same structure.

A flexible conceptual hierarchy is:

``` text
Library
└── Book
    └── Content Collection
        └── Saint / Subject
            └── Section
                └── Subsection
                    └── Content Item
                        ├── Original Text (paragraphs with stable IDs)
                        ├── Source Page References
                        ├── Summary
                        ├── Key Points
                        ├── Spiritual Lessons
                        └── Keywords
```

For Bustan Al-Rohban, a saint may contain sections such as biography,
ascetic life, spiritual struggle, sayings, advice, or other headings
found in the actual source. These are examples, not a fixed mandatory
list. The content must preserve the book's real headings and order.

### 5.2 Original text requirements

-   Preserve the original Arabic text faithfully.
-   Do not silently rewrite, modernize, or paraphrase the original.
-   Preserve meaningful paragraph boundaries and headings.
-   Preserve page references to the source edition.
-   Record extraction issues for human correction.
-   Keep editorial additions visually distinct from the original source.
-   Do not fabricate page numbers when the source mapping is uncertain
    (use `null`).
-   Every paragraph has a stable, never-reused ID (see
    `docs/CONTENT_SCHEMA.md`).

### 5.3 Prepared insights

The content preparation process may create:

-   Short summary.
-   Key points.
-   Spiritual lessons.
-   Keywords and search terms.

These are editorial/AI-assisted additions, not original quotations. They
must be reviewed and approved by the owner before being shipped in the
application.

Each insight should retain: - The content item it describes. - The
source paragraph IDs supporting it. - Its review status. - Its content
version. - The reviewer or approval record where appropriate.

### 5.4 Content preparation pipeline

1.  Owner supplies extracted Arabic text files in the authoring format.
2.  A repeatable converter/validator (built in Task 1, applied to real
    files in Task 13) turns them into validated JSON.
3.  The validator reports broken IDs, ordering problems, missing or
    uncertain page mappings, empty paragraphs, and suspicious
    characters. The owner corrects the source text files.
4.  Draft summaries, key points, lessons, and keywords may be generated
    from the real text and are reviewed by the owner.
5.  Export validated JSON assets for the Flutter application.
6.  Export the same approved corpus for backend indexing.
7.  Run consistency checks so local and server content versions match.

------------------------------------------------------------------------

## 6. Orthodox Doctrine and AI Assistant Policy

This is a core product requirement, not a cosmetic prompt instruction.

The AI assistant must provide explanations consistent with the
doctrine, worship, and received tradition of the **Coptic Orthodox
Church**. It must not behave as an unrestricted religious chatbot.

### 6.1 Authority and source policy (Version 1)

The assistant's **only** retrieval source in Version 1 is the original
Bustan Al-Rohban text shipped with the application (and indexed on the
backend from the same approved files).

Other sources (other books, church documents, patristic writings,
websites) are **not** used by the AI in Version 1. They may be added
only through a future approved SPEC change that follows the review
workflow in §6.5.

The project owner approves the book corpus and is the designated
reviewer of AI behavior and theological content for Version 1. A
separate Orthodox theological reviewer may be appointed later; if so,
record the name and scope in §20.

### 6.2 Required AI behavior

The assistant must:

-   Answer in clear Arabic by default, using accessible language without
    distorting theological meaning.
-   Respect the doctrine and tradition of the Coptic Orthodox Church.
-   Answer **only** from retrieved book passages.
-   Cite the saint, section, paragraph, and page supporting its answer
    whenever available.
-   Clearly distinguish:
    -   A direct quotation.
    -   A paraphrase of a source.
    -   A cautious inference.
-   Preserve the historical and literary context of quotations.
-   Say when the book does not address a question.
-   Say when the retrieved passages are insufficient or unclear.
-   Avoid inventing quotations, page references, saints' sayings,
    historical events, or doctrinal claims.
-   Avoid presenting disputed interpretations as universally accepted
    teaching.
-   Avoid pretending to be a priest, confessor, bishop, theologian, or
    spiritual authority.
-   Encourage the user to consult their father of confession or an
    appropriate priest for personal spiritual guidance.

### 6.3 Prohibited AI behavior

The assistant must not:

-   Contradict Coptic Orthodox doctrine or present another
    denomination's teaching as Coptic Orthodox teaching.
-   Invent doctrine or claim that an unsupported opinion is official
    church teaching.
-   Fabricate patristic quotations or citations.
-   Give a definitive answer when the book does not support one.
-   Answer from general model knowledge when retrieval is insufficient.
-   Issue personal absolution, sacramental rulings, or replace
    confession and pastoral guidance.
-   Encourage the user to disregard their priest, confession father, or
    church.
-   Use sectarian insults, mock other churches, or provoke religious
    hostility.
-   Claim that an AI-generated answer is an official church statement.
-   Present generated spiritual advice as a substitute for the user's
    relationship with their priest and church.

### 6.4 Uncertainty and sensitive questions

For questions involving doctrine, church practice, sacraments,
confession, marriage, fasting, spiritual discipline, or personal crises:

-   Retrieve relevant book passages.
-   Provide a limited explanation only when the passages support it.
-   Clearly state uncertainty or differences in interpretation where
    relevant.
-   Refer personal or case-specific decisions to the user's priest or
    confession father.
-   Do not make up a definitive answer to appear helpful.

**Ascetic practices.** The book describes extreme ascetic practices
(for example severe fasting, sleep deprivation, isolation). The
assistant may report what the book says about a saint, as history, but
must not present these practices as instructions, prescriptions, or
personal advice for the user, and must not give medical or
mental-health advice. Where a user appears to be considering such
practices for themselves, or shows signs of distress, the assistant
responds with care, refers them to their father of confession, and to a
qualified professional or emergency help where appropriate.

For medical, legal, psychological, or emergency questions, the assistant
must not substitute for a qualified professional. It may provide general
safe information and direct the user to appropriate help.

### 6.5 Review workflow

Before the book corpus (or any future source) is enabled for AI
retrieval:

1.  Record its title, author, edition/translation, publisher or origin,
    and rights status.
2.  Have the designated reviewer approve it. For Version 1 this is the
    project owner.
3.  Record the approval status and date.
4.  Index only approved material.
5.  Re-review material when its edition, translation, or content
    changes.

AI prompt instructions alone are not sufficient to guarantee doctrinal
alignment. Alignment must also be enforced through source selection,
retrieval constraints, evaluation tests, refusal behavior, and human
review.

### 6.6 AI evaluation set

Create the evaluation set **early (alongside backend Task 10b)**, not
only before release. It should include:

-   Straightforward questions answered directly by the book.
-   Questions requiring more than one passage.
-   Questions whose answers are not present in the book.
-   Questions based on a false premise.
-   Requests for a quotation with a page reference.
-   Questions about Orthodox terminology.
-   Questions about disputed or sensitive topics.
-   Questions about ascetic practices as personal advice.
-   Attempts to make the assistant contradict Orthodox doctrine.
-   Attempts to make the assistant invent a saint's quotation.
-   Attempts to broaden scope to another saint through the prompt or
    prior messages.
-   Prompt-injection text inside user messages and inside source text.
-   Requests for personal confession or sacramental decisions.

The owner approves expected answers or expected safe behavior.

**Pass thresholds (release-blocking):**

-   100% citation validity (every returned citation ID was retrieved for
    that request and resolves to a real paragraph/page).
-   100% of quoted text is a verbatim substring of a retrieved passage.
-   100% refusal on "not in the book" cases.
-   0 critical doctrinal failures, 0 scope-isolation failures.
-   Non-critical categories: threshold set by the owner and recorded in
    the repository before the first evaluation run.

Retrieval-quality results on FAKE fixtures prove plumbing only. Arabic
retrieval quality is judged after real content is imported (Task 13).

------------------------------------------------------------------------

## 7. AI Chat --- Version 1

### 7.1 Functional requirements

-   Chat is included in Version 1.
-   Chat requires an internet connection to send new messages.
-   The user can ask questions in Arabic.
-   The chat can receive context from the currently selected saint or
    section.
-   The user can start a question scoped to the whole book
    (`book_scope`).
-   Responses should include source references when retrieval supports
    them.
-   The UI must distinguish source quotations from AI-generated
    explanation.
-   The UI shows a clear "answers from Bustan Al-Rohban only" indicator.
-   The UI must show loading, empty, error, timeout, and offline states.
-   The app must preserve local reading functionality if chat is
    unavailable.
-   Existing conversations remain readable offline.

### 7.2 Retrieval-augmented generation

Use a RAG approach rather than asking the language model to answer from
its general knowledge alone.

Conceptual request flow:

``` text
Flutter App
    |
    | User question + conversation context + scope
    v
Backend API
    |
    v
App attestation / Rate limit / Spend cap / Validation
    |
    v
Query processing
    |
    v
Retrieve passages from Bustan Al-Rohban (scope filter applied in the DB)
    |
    v
Sufficient-evidence check (refuse if insufficient)
    |
    v
LLM generates structured, grounded answer (non-streaming)
    |
    v
Validate citations and quotations against retrieved passages
    |
    v
Flutter displays answer + references
```

The retrieval system must preserve source metadata such as book, saint,
section, paragraph ID, page, edition, content version, and approval
status.

Retrieval design (chunking, lexical plus semantic/hybrid search,
Arabic normalization, saint-name alias handling, and a measurable
"sufficient evidence" rule) is defined and tested in Tasks 10a-10b and
re-evaluated on real content in Task 13.

### 7.3 Chat answer format

The model returns a **structured** response (not free text) containing:
answer text, a list of citations (paragraph IDs), optional short
quotations tied to a paragraph ID, a flag for uncertain/unsupported, and
an optional pastoral-referral flag.

Do not force citations to appear if no reliable source was retrieved. In
that case, the assistant explains that it could not find sufficient
support in the book.

**Streaming decision (Version 1):** non-streaming. Citation and
quotation validation needs the complete answer before anything is shown.
Revisit later only with a buffered-validation design.

### 7.4 Local chat history and privacy

Chat history is a Version 1 requirement and must be stored locally only.
There is no server-side conversation history, cloud sync, or user account
requirement.

Local persistence requirements:

-   Store conversations and messages in the app's local SQLite database,
    using Drift as the proposed SQLite abstraction.
-   Give every conversation a stable, locally generated unique ID.
-   Store messages in order with an explicit role (`user` or
    `assistant`), content, creation timestamp, and delivery/status
    metadata where needed.
-   Store conversation metadata including title, creation time, last
    updated time, chat mode, and the relevant book/saint/section IDs.
-   **Conversation title** is derived locally from the first user
    question (truncated); no extra AI call.
-   Show a conversation history list, ordered by most recently updated.
-   Allow the user to reopen and continue a previous conversation.
-   Allow deleting one conversation and clearing all local chat history.
-   Deleting local history must not require a server request.
-   Preserve history across app restarts and normal app updates, subject
    to platform storage behavior. Uninstalling the app or clearing its
    data may remove the history; explain this limitation to users.
-   Old conversations are readable offline; only sending a new message
    requires internet.

When continuing a conversation, the Flutter app sends the new question
and a bounded, relevant selection of prior messages to the backend so
the model can understand the conversation. The backend uses that
transient request context to generate the response and must not persist
the conversation or message payload. The AI provider necessarily
receives the prompt/context required to process the request; therefore
"local-only history" means local persistence, not that messages never
leave the device. Disclose this clearly in the privacy notice.

Do not send the entire history blindly. Apply a configurable context
window/token budget, preserve recent conversational turns, and include
older messages only when useful. Retrieved book passages remain separate
from conversation history and must be independently filtered by the
active chat scope.

Operational logs may contain request IDs, provider/model identifiers,
latency, token counts, estimated cost, status, and error categories. They
must not contain full prompts, message text, retrieved passage text,
provider secrets, or unnecessary personal data. Any temporary request
buffers must be discarded after processing and not written to persistent
application logs, analytics, or database tables.

No private chat content may be used for model training by the project.
Provider-side data handling depends on the selected provider/account
terms and configuration; verify these terms and disclose them before
launch rather than promising that an external provider never retains
request data.

### 7.5 AI providers, models, and cost control

The backend must support multiple AI providers through a provider
adapter abstraction. Version 1 providers (**both implemented in this
release**):

-   OpenAI API (models configured by the project administrator).
-   Google Gemini API (models configured by the project administrator).

The Flutter app must call only the project's backend API. It must never
call OpenAI or Gemini directly and must never contain provider API keys.
The backend owns provider credentials, request formatting, response
normalization, timeout handling, usage extraction, and provider-specific
error mapping.

Provider/model selection is an administrator-controlled backend
configuration, not a user-facing setting in Version 1. The user sees one
consistent AI assistant. Changing the configured provider or model must
not require a Flutter release, provided the backend response contract
remains compatible. Keep provider/model identifiers in configuration,
not hard-coded throughout business logic.

Do not silently switch providers for a request unless an explicit
operational fallback policy has been configured and tested. Record which
provider and model actually served each request.

For each completed request, capture available usage metadata including
input tokens, output tokens, total tokens, provider, model, and request
status. Calculate estimated cost using a versioned pricing configuration
that can be updated when provider prices change. Distinguish estimated
cost from an authoritative provider invoice. If a provider does not return
usage data, mark the usage/cost as unavailable or estimated; never invent
a precise value.

Cost and operational metrics must be aggregated without retaining chat
content.

**Anonymous abuse protection (no user accounts).** A bundled API key can
be extracted and a client-supplied installation ID is not authentication.
Version 1 therefore requires:

-   Configurable per-IP and per-installation rate limits.
-   Android app attestation (Google Play Integrity) verified by the
    backend before serving chat requests. If attestation cannot be
    implemented, record the residual risk in §20.
-   A **global daily spend cap** with an automatic kill switch that
    returns a friendly "temporarily unavailable" response when reached.
-   Request size limits and message-count limits.

### 7.6 Book-scoped RAG and answer grounding

RAG is mandatory. The language model must not be allowed to answer from
general model knowledge when the book corpus does not support the
answer. Prompt wording alone is not a security or grounding boundary.

The request must identify its chat mode and scope. Supported modes:

-   `saint_scope`: restrict retrieval to the selected saint's content
    (and optionally one section).
-   `book_scope`: retrieve across Bustan Al-Rohban only.

(`library_scope` in SPEC v1.1 is renamed `book_scope`; the library
contains one book in Version 1.)

When a conversation is opened from a saint page, its saint ID and
`saint_scope` are saved locally and reused for follow-up messages. The
backend must validate the scope and apply it as a retrieval/database
filter before passages reach the model. Do not rely on the model to
respect a saint name mentioned in the prompt. If the user changes scope,
make that transition explicit in the UI and request.

For every request:

1. Validate the requested mode, saint/book/section IDs, and message
   structure.
2. Apply the book allowlist and scope filters.
3. Retrieve relevant source passages and retain their exact metadata.
4. Check whether retrieval provides sufficient evidence.
5. If evidence is insufficient, return a grounded "not found in the
   book" response instead of asking the model to fill gaps from memory.
6. If evidence is sufficient, send only the necessary passages, the
   bounded conversation context, and the new question to the configured
   model.
7. Validate returned citation IDs against the passages actually
   retrieved for this request, and check that every quotation is a
   verbatim substring of its cited passage.
8. Reject and refuse (or retry once) when validation fails.
9. Return the answer and validated references.

Conversation history provides dialogue context only; it is not an
authoritative source and must never broaden the retrieval scope. User
messages, previous AI messages, and retrieved documents are untrusted
input for prompt-injection purposes. Instructions embedded in source
text or user messages must not override system policy, retrieval
filters, or the book allowlist.

The backend must not claim that a response is supported by a source
unless the cited passage was retrieved and validated for that request.

### 7.7 Backend security

-   Never embed the LLM provider secret key in the Flutter application.
-   All model requests must pass through the backend.
-   Apply request validation, rate limits, timeouts, spend caps, and
    abuse protection (§7.5).
-   Keep provider credentials in server-side secret storage.
-   Avoid returning internal prompts, credentials, or private retrieval
    metadata.
-   Validate citation IDs against actual retrieved source records.
-   Use HTTPS for network communication.

### 7.8 Report an answer

The user can report an AI answer (reason category plus optional note).
The report is sent to the backend and stored **without the conversation
history**: it contains only the reported answer text, the question that
produced it, the cited paragraph IDs, content version, provider/model,
and the user's reason, and the user is told exactly what is sent before
they confirm. Reports are for owner review and are not used for model
training. This also supports Google Play's AI-generated-content
policy.

------------------------------------------------------------------------

## 8. Offline-First Requirements

### 8.1 Offline features

The following must work without internet after successful installation:

-   Opening the application.
-   Browsing the installed book.
-   Reading original text.
-   Viewing prepared summaries and key points.
-   Local search.
-   Bookmarks.
-   Reading progress.
-   Reading preferences.
-   Reading existing chat conversations.
-   TTS, provided the device has a compatible Arabic offline voice
    installed.

### 8.2 Online-only features

-   Sending new AI chat messages.
-   Reporting an AI answer.
-   Server-side retrieval and LLM generation.
-   Any future server content updates or synchronization.

### 8.3 Offline failure behavior

If the user opens chat without internet: - Display a clear message that
internet is required to send new messages. - Do not block or degrade
local reading features or reading old conversations. - Preserve the
user's typed question where practical. - Do not imply that a response
was generated when the request failed.

The app must not require a network call to open the book or read
previously installed content.

------------------------------------------------------------------------

## 9. Text-to-Speech

### 9.1 Requirements

Use the device's native TTS engine through a Flutter integration such as
`flutter_tts`, subject to technical validation (**feasibility spike S1,
before the reader is built**).

Required controls: - Play. - Pause. - Resume. - Stop. - Reading speed. -
Current reading position where supported.

The implementation should handle long passages by splitting them into
safe chunks and sequencing them without losing their order.

### 9.2 Offline and language constraints

Offline Arabic speech is dependent on: - The Android device. - The
installed TTS engine. - Whether an Arabic voice/language package is
installed. - Whether that engine supports offline synthesis for the
selected voice.

Therefore: - Do not promise identical Arabic voice quality on every
Android device. - Detect or test Arabic language availability where the
plugin supports it. - Explain how the user can install or enable an
offline Arabic voice if necessary. - Test on the actual target devices
before release. - If no suitable offline Arabic voice is available, show
a clear limitation instead of silently switching to an online service. -
Unvowelled Arabic is often mispronounced by TTS engines; document known
limitations found in the spike.

### 9.3 Background playback

Background playback is desired, but must be validated with the selected
Flutter and Android audio integrations. If supported, implement the
required foreground service/notification behavior (including Android
foreground-service type rules) and lifecycle handling.

Do not claim background playback is complete until tested with: - Screen
locked. - App in background. - Incoming interruption. - Audio focus
changes. - User stopping playback from the notification. - Long content
across multiple chunks.

### 9.4 Audio file caching

Generating and storing an audio file for every passage is not required
in Version 1. Native TTS engines do not all expose a reliable way to
export synthesized speech to a file. Treat audio caching as a later
optional capability after a technical proof of concept.

------------------------------------------------------------------------

## 10. Flutter Application Architecture

### 10.1 Proposed stack

  -----------------------------------------------------------------------
  Area                                Proposed technology
  ----------------------------------- -----------------------------------
  Mobile UI                           Flutter / Dart

  State management                    BLoC / Cubit

  Local structured content            JSON assets (manifest plus one file
                                      per saint; see
                                      `docs/CONTENT_SCHEMA.md`)

  Local user data                     SQLite

  SQLite abstraction                  Drift

  Local search                        SQLite FTS with a normalized search
                                      column (allowed exception to §11.2)

  Text-to-speech                      Native Android TTS through a
                                      Flutter plugin

  Backend API                         NestJS

  Server database                     PostgreSQL (proposed)

  Retrieval                           Hybrid lexical plus semantic
                                      retrieval, technology to be
                                      selected in Task 10a

  AI generation                       Server-side LLM provider
                                      integration (OpenAI and Gemini)

  API transport                       HTTPS / REST initially
  -----------------------------------------------------------------------

These are proposed implementation choices, not reasons to add
unnecessary abstractions. The final technical design may refine them
while preserving the product requirements.

### 10.2 Practical feature-based structure

A suggested structure:

``` text
lib/
  app/
    app.dart
    router/
    theme/
  core/
    content/
    search/
    errors/
    utils/
    services/
    widgets/
  features/
    library/
      data/
      presentation/
    reader/
      data/
      presentation/
    search/
      data/
      presentation/
    bookmarks/
      data/
      presentation/
    audio/
      data/
      presentation/
    insights/
      data/
      presentation/
    settings/
      data/
      presentation/
    ai_chat/
      data/
      presentation/
```

Keep domain abstractions where they represent meaningful business rules
or isolate important dependencies. Do not create layers, interfaces, or
use cases mechanically for every small operation.

### 10.3 State management

Use BLoC/Cubit for feature state where it improves separation and
testability.

Each feature should own its relevant state and UI behavior. Avoid one
giant application-wide Cubit for unrelated features.

------------------------------------------------------------------------

## 11. Data Management

### 11.1 Static content

The installed book and reviewed insights are shipped as JSON assets,
split into a manifest and one file per saint so the app does not parse
the whole book at once.

Static content includes: - Book metadata. - Saints and their ordering. -
Sections and subsections. - Original text as paragraphs with stable IDs.
- Source page references. - Summaries. - Key points. - Spiritual
lessons. - Keywords. - Content version metadata.

### 11.2 Dynamic local data

SQLite/Drift stores user-specific and changing local data, such as: -
Bookmarks. - Reading progress. - Last opened content item. - TTS
playback position, where reliable. - Reading preferences. - Local chat
conversation history (required, see §7.4).

Do not duplicate the complete static book content into SQLite unless a
measured requirement justifies it. **Allowed exception:** a derived,
normalized FTS search index built from the JSON content (Task 4). The
displayed text always comes from the original JSON, never from the
normalized column.

Local chat data model (conceptual):

| Table | Important fields |
|---|---|
| `chat_conversations` | `id` (UUID/text primary key), `title`, `mode`, `book_id`, `saint_id`, `section_id`, `created_at`, `updated_at` |
| `chat_messages` | `id`, `conversation_id` (foreign key), `role`, `content`, `created_at`, `status`, optional `error_code` |

Use a stable ordering key (timestamp plus sequence/ID) so messages remain
in their original order. Add an index on conversation update time and
message conversation/order fields. Apply SQLite foreign-key constraints;
deleting a conversation should cascade-delete its messages. Store no
provider API keys or server-side conversation copies in this database.

Bookmarks and reading progress reference **paragraph IDs plus an
offset**, never list positions, so they survive content re-ordering.

The local history database is private app storage. Chat history is
**excluded from Android cloud/device backups** (backup rules configured
in Task 9) and the behavior is documented in the privacy notice.

### 11.3 Content model

The authoritative content format, ID rules, authoring text format, and
validation rules are in `docs/CONTENT_SCHEMA.md`. The conceptual shape:

``` json
{
  "bookId": "bustan-al-rohban",
  "title": "بستان الرهبان",
  "language": "ar",
  "contentVersion": 1,
  "saints": [
    {
      "id": "saint-example",
      "title": "اسم القديس",
      "order": 1,
      "sections": [
        {
          "id": "section-example",
          "title": "عنوان القسم كما ورد في الكتاب",
          "order": 1,
          "paragraphs": [
            { "id": "p-000001", "order": 1, "page": 1, "text": "النص الأصلي..." }
          ]
        }
      ]
    }
  ]
}
```

Actual IDs, titles, page numbers, and content must come from the
owner-supplied text files. Do not use this sample as real book data.

### 11.4 Versioning

-   Include a content version.
-   Keep local and server corpus versions identifiable.
-   Ensure that citations from chat resolve to the correct edition and
    page mapping.
-   Define a migration strategy before changing the JSON schema
    (`schemaVersion`).
-   Do not overwrite user progress when content ordering changes; use
    stable IDs. Paragraph IDs are never reused.

------------------------------------------------------------------------

## 12. Backend Architecture

The backend is required in Version 1 because AI chat is included.

### 12.1 Responsibilities

-   Receive and validate chat requests.
-   Enforce rate limits, attestation, and spend caps.
-   Maintain book/source metadata and the approved corpus version.
-   Retrieve relevant passages (Bustan Al-Rohban only).
-   Call the configured LLM provider securely.
-   Apply refusal and response policies.
-   Validate and return source references and quotations.
-   Accept answer reports (§7.8).
-   Record only privacy-compliant operational metadata (for example request
    status, provider/model, latency, token usage, and estimated cost);
    never persist chat text or full prompts.

### 12.2 Suggested initial modules

``` text
backend/
  src/
    chat/
    retrieval/
    sources/
    providers/
    theological-policy/
    abuse-protection/
    reports/
    health/
    common/
```

This is a starting point, not a requirement to create a complex
microservice system. A modular monolith is sufficient for the first
release unless real scale or operational needs justify separation.

### 12.3 Stateless chat API contract (conceptual)

A chat request should contain:

-   `conversationId`: client-generated local conversation identifier;
    correlation only, not a server-side history key.
-   `mode`: `saint_scope` or `book_scope`.
-   `scope`: book/saint/section identifiers relevant to the mode.
-   `messages`: bounded ordered context messages plus the new user
    message, each with a role and text.
-   Optional client request ID for safe diagnostics/idempotency.
-   App attestation token.

The response should contain the structured assistant answer, validated
source references, provider/model metadata safe to expose, and usage
metadata where appropriate. Do not return internal prompts, secret
configuration, or private retrieval implementation details.

The backend treats `conversationId` as an opaque correlation value. It
must not use it to load, create, or append to a server-side conversation
record. The backend processes the request and returns the result without
persisting the supplied message array.

This contract is illustrative; exact routes and DTO names are
implementation decisions, subject to the Task 10b decision to stay
non-streaming in Version 1.

### 12.4 Database and retrieval

PostgreSQL is the proposed primary database for server-side book
metadata, retrieval indexing, provider configuration, answer reports,
and minimal operational usage metadata. It must not store chat
conversations or message bodies.

Retrieval technology (full-text, vector extension, or both) is chosen in
Task 10a after testing Arabic retrieval quality, deployment complexity,
cost, and citation accuracy.

The retrieval index must: - Include only the approved book corpus. -
Preserve source/paragraph/page metadata. - Support Arabic text and
relevant normalization carefully. - Include a saint alias table so
saint name variants resolve to the right saint ID. - Return exact source
passages, not just generated summaries. - Track corpus version and
approval status.

------------------------------------------------------------------------

## 13. User Interface and Experience

### 13.1 Main screens

The first release should include:

1.  Home / library screen.
2.  Book overview.
3.  Saints or subjects list.
4.  Saint detail / section list.
5.  Reader screen.
6.  Search screen and results.
7.  Prepared insights view.
8.  AI chat screen with conversation history access.
9.  Local chat history list and conversation actions (open, delete one,
    clear all).
10. Bookmarks.
11. Basic settings (including dark mode).

### 13.2 Reader experience

-   Arabic right-to-left layout.
-   Readable Arabic typography.
-   Clear hierarchy between book title, saint, section, and body text.
-   Comfortable line spacing and adjustable text size.
-   Source page reference visible where available.
-   Easy access to bookmark and TTS controls.
-   Clear distinction between original text and editorial insights.

### 13.3 Accessibility and usability

-   Support Android system text scaling where practical.
-   Use readable contrast, including in dark mode.
-   Ensure touch targets are usable.
-   Do not rely on color alone to communicate status.
-   Handle long Arabic text without clipping or broken layout.
-   Test right-to-left behavior in navigation, lists, search, and chat.
-   Test with TalkBack.

The final visual design system, typography, and exact navigation pattern
remain to be agreed during UI design. The Arabic typeface licence must be
verified before release.

------------------------------------------------------------------------

## 14. Non-Functional Requirements

### 14.1 Performance

-   The installed book should open without waiting for a network
    request.
-   Local navigation and search should remain responsive on agreed
    target devices.
-   Load content per saint on demand; avoid parsing or rendering the
    entire book at once.
-   TTS chunking must not cause repeated or skipped text.
-   Chat should have loading and timeout handling.

Exact performance budgets should be set after measuring the real content
size and target devices.

### 14.2 Reliability

-   Reading progress and bookmarks must survive application restarts.
-   A failed chat request must not corrupt local data.
-   A malformed content asset must be detected by validation/tests.
-   TTS interruptions must leave the playback state recoverable where
    possible.

### 14.3 Security and privacy

-   Do not store AI provider secrets in the app.
-   Use HTTPS.
-   Validate backend input.
-   Apply rate limits and spend caps.
-   Minimize personal data collection.
-   Do not persist chat messages or conversation history on the backend.
-   Persist chat history only in local SQLite/Drift storage.
-   Explain that messages and bounded prior context are transmitted to
    the backend and selected AI provider for each request.
-   Provide a privacy policy before public release.
-   Do not send reading history to the backend unless a feature
    explicitly requires it and the user is informed.
-   Crash reporting, if used, must not capture chat text or reading
    content, and must be disclosed.

### 14.4 Maintainability

-   Keep content separate from UI code.
-   Use stable content IDs.
-   Add tests around parsing, search, progress, TTS sequencing,
    retrieval, and citation validation.
-   Document environment variables and deployment steps without
    committing secrets.

### 14.5 Compatibility

The initial target is Android. Minimum Android version and the exact
supported device matrix must be confirmed before release. Do not claim
compatibility with every device until tested.

------------------------------------------------------------------------

## 15. Testing Strategy

### 15.1 Flutter tests

-   JSON parsing and validation.
-   Content hierarchy and ordering.
-   Reader rendering for long Arabic passages.
-   Local search matching and Arabic normalization.
-   Bookmark persistence.
-   Reading progress persistence.
-   TTS chunk ordering and playback state transitions.
-   Offline behavior.
-   RTL layout and navigation.
-   Local chat history CRUD, ordering, restart persistence, and
    deletion.
-   Context-window trimming while preserving recent turns and scope.

### 15.2 Backend tests

-   Request validation.
-   Rate limiting, attestation failure, and spend-cap kill switch.
-   Retrieval relevance.
-   Arabic query handling and saint alias resolution.
-   Book-only filtering.
-   Citation and verbatim-quotation correctness.
-   LLM timeout and provider failure.
-   Prompt-injection resistance (user input and source text).
-   Sensitive-question and ascetic-practice handling.
-   Privacy-safe logging with assertions that message text/prompts are
    not persisted.
-   Stateless backend behavior: no conversation/message rows are written.
-   OpenAI and Gemini adapter contract tests using mocked provider APIs.
-   Provider/model configuration changes without Flutter changes.
-   Token usage and estimated-cost calculation, including missing usage
    metadata and pricing-version changes.
-   Saint-scope retrieval isolation and attempts to broaden scope through
    user prompts or prior conversation messages.
-   Answer-report storage contains no conversation history.

### 15.3 Theological and content tests

The owner reviews: - The book text (and the extraction/page mapping
reports). - Prepared summaries and spiritual lessons. - The AI system
instructions and refusal behavior. - The evaluation test set and its
thresholds. - Representative AI responses before release.

The application must not claim official church endorsement unless
explicit authorization has been obtained.

------------------------------------------------------------------------

## 16. Acceptance Criteria --- Version 1

Version 1 is not complete until all applicable criteria below pass.

### 16.1 Offline library

-   [ ] The application opens without internet.
-   [ ] Bustan Al-Rohban (real content) is available after installation.
-   [ ] No FAKE fixture content exists in the release build.
-   [ ] Users can browse saints and the actual section hierarchy.
-   [ ] Original text is displayed without unintended rewriting.
-   [ ] Source page references are available where verified.
-   [ ] Local search returns relevant installed content without
    internet.
-   [ ] Summaries, key points, and spiritual lessons are available
    offline.

### 16.2 Local user features

-   [ ] Users can add and remove bookmarks.
-   [ ] Reading progress is saved.
-   [ ] The last reading position is restored after restart.
-   [ ] Basic reading preferences persist.

### 16.3 TTS

-   [ ] Arabic voice availability is checked or clearly explained.
-   [ ] Playback works on the agreed test devices with an installed
    offline Arabic voice.
-   [ ] Play, pause, resume, and stop work.
-   [ ] Long text is read in the correct order.
-   [ ] Speed control works where supported.
-   [ ] Background playback is accepted only if it passes the defined
    device/lifecycle tests.

### 16.4 Local chat history

-   [ ] The user can create multiple independent conversations.
-   [ ] Each conversation has a stable local ID and saved saint/section
    scope metadata.
-   [ ] Conversation list is ordered by last update.
-   [ ] Messages persist locally across app restarts.
-   [ ] The user can reopen and continue an old conversation.
-   [ ] The user can delete one conversation or clear all history.
-   [ ] No account is required for local history.
-   [ ] Chat history is excluded from Android backups.
-   [ ] Old conversations are readable offline.

### 16.5 AI chat and backend

-   [ ] Chat is available and clearly indicates that internet is
    required to send messages.
-   [ ] The UI states that answers come from Bustan Al-Rohban only.
-   [ ] The backend does not persist conversation IDs as history records,
    message bodies, or full prompts.
-   [ ] Prior messages are sent only as bounded request context when a
    conversation is continued.
-   [ ] OpenAI and Gemini are both supported behind a backend provider
    adapter.
-   [ ] The active provider/model is controlled by backend configuration,
    not selected by the end user in Version 1.
-   [ ] Provider API keys exist only in server-side secret storage.
-   [ ] Token usage and estimated request cost are recorded without chat
    content.
-   [ ] The backend retrieves only the approved book corpus.
-   [ ] Saint-scoped retrieval cannot return passages from another saint,
    even when the prompt or earlier messages ask for it.
-   [ ] Responses use the current reading context when supplied.
-   [ ] Citations point to real paragraph records with correct
    page/section metadata, and quotations are verbatim substrings.
-   [ ] Unsupported questions are declined rather than completed from
    general model knowledge.
-   [ ] Ascetic-practice and personal-guidance questions follow §6.4.
-   [ ] The user can report an answer (§7.8).
-   [ ] Evaluation thresholds in §6.6 are met and owner-approved.
-   [ ] The app's offline reading features continue to work when chat
    fails.

### 16.6 Security and release

-   [ ] No LLM provider secret is present in the Flutter app bundle.
-   [ ] HTTPS is used.
-   [ ] Rate limits, app attestation, and the global spend cap are
    enabled.
-   [ ] Privacy notice explains local-only history and transient
    transmission to the backend/AI provider.
-   [ ] Google Play Data Safety and AI-content disclosures are prepared.
-   [ ] Operational-log retention and provider data-handling settings are
    reviewed and documented; chat message bodies are never retained by
    the backend.
-   [ ] Arabic font licence verified.
-   [ ] TalkBack and dark mode checked.
-   [ ] The app has been tested on the agreed Android device matrix.

------------------------------------------------------------------------

## 17. Rights, Attribution, and Editorial Responsibility

**Status (2026-11-15):** The project owner confirms that they own the
rights to the book content and the website `coptic-treasures.com`. The
rights gate is **resolved by the owner**. Record the exact edition,
publisher, year, and required attribution in `docs/CONTENT_SCHEMA.md`
metadata (`book.edition`) when the real files arrive.

Still required:

-   Verify rights for any future additional books, translations, and
    patristic sources before they are added.
-   Record required attribution.
-   Do not publish generated audio files unless the relevant text and
    audio distribution rights are clear.
-   Verify the licence of the Arabic typeface used in the app.

The project owner is responsible for theological review and approves
content for publication.

------------------------------------------------------------------------

## 18. Delivery Plan

The delivery plan is in `ROADMAP.md` (tasks 0-13, with approval gate
after each task). The earlier phase list is superseded by it.

------------------------------------------------------------------------

## 19. Open Decisions

Do not silently invent answers to these. Track them here.

| # | Decision | Status |
|---|---|---|
| 1 | Exact edition, publisher, year | Owner to record in book metadata when files arrive (rights resolved) |
| 2 | Initial content coverage (full book or subset) | Open; decided at Task 13 |
| 3 | Orthodox theological reviewer | Resolved for V1: owner. Revisit if a church reviewer is appointed |
| 4 | Additional approved AI sources | Resolved: none in V1 (book-only) |
| 5 | AI operating budget, rate limits, daily cap | Open; needed before Task 10d |
| 6 | Initial provider/model | Open; admin config, decide at Task 10c/10d |
| 7 | Minimum Android version and test devices | Open; needed before Task 12b |
| 8 | Background audio: release-blocking or best-effort | Open; decide after spike S1 |
| 9 | Visual identity (logo, colors, typography) | Open |
| 10 | Church endorsement | Independent project; no endorsement claimed |

------------------------------------------------------------------------

## 20. Decisions Confirmed for Version 1

### 20.1 Confirmed 2026-11-15 (SPEC v1.1)

1. Chat history is stored on the user's device only, using SQLite/Drift.
2. The backend does not store conversations or message bodies.
3. There are no user accounts in Version 1.
4. When continuing a local conversation, the app sends a bounded set of
   prior messages with the new question so the model can understand the
   dialogue. These messages are transiently processed by the backend and
   selected AI provider; they are not persisted as server history.
5. The backend supports OpenAI and Google Gemini through a provider
   abstraction.
6. The administrator selects the active provider/model in backend
   configuration. The end user does not choose a provider in Version 1.
7. Provider API keys are stored only on the backend.
8. Saint-specific chat uses retrieval filters that restrict evidence to
   the selected saint. The model must not fill unsupported gaps from
   general knowledge.
9. Token usage and estimated request cost are measured without storing
   conversation content.

### 20.2 Confirmed 2026-11-15 (SPEC v1.2, from the approved roadmap)

10. **RAG scope is Bustan Al-Rohban only.** No other books or sources are
    retrieved in Version 1. `library_scope` is renamed `book_scope`.
11. **Real book content is supplied by the owner as extracted text files**
    in the authoring format of `docs/CONTENT_SCHEMA.md`. The
    implementation team does not extract the PDF or run OCR.
12. Until real files arrive, development uses three clearly labeled FAKE
    saints with 2-3 sections each. FAKE content never ships.
13. **Rights gate is owner-confirmed and resolved** (§17).
14. **The owner reviews all AI answers and theological content.**
15. Both OpenAI and Gemini adapters are implemented in Version 1.
16. The AI refuses when retrieved book evidence is insufficient; it never
    substitutes general model knowledge.
17. Chat is non-streaming in Version 1 (citation/quotation validation).
18. Conversation titles are derived locally from the first question.
19. Anonymous abuse protection: rate limits, Play Integrity attestation,
    and a global daily spend cap with kill switch (§7.5).
20. A "report this answer" feature is part of Version 1 (§7.8).
21. Chat history is excluded from Android backups (§11.2).
22. A TTS feasibility spike (S1) runs before the reader is built.
23. Real content import and re-testing (Task 13) is part of Version 1.

These decisions do not remove the need to disclose that user messages
and relevant prior context are transmitted to an external AI provider for
processing. Provider retention and training settings must be checked
against the actual provider account and terms before launch.

------------------------------------------------------------------------

## 21. Change Management

-   This document is the baseline for Version 1.
-   Any change to scope, offline/online behavior, doctrine policy, data
    model, or architecture must be recorded here.
-   Record significant decisions with date, reason, and impact.
-   Keep implementation tasks aligned with this document and
    `ROADMAP.md`.
-   Update acceptance criteria whenever an approved requirement changes.
-   Do not treat an AI-generated suggestion as an approved product or
    theological decision.

------------------------------------------------------------------------

## 22. Definition of Done

A feature is done only when:

1.  Its behavior matches this specification.
2.  Its loading, empty, error, and offline states are handled where
    relevant.
3.  It has appropriate tests (unit and widget tests where applicable).
4.  It has been reviewed on the target platform.
5.  It does not break offline reading.
6.  Any content or theological claims have passed the required review.
7.  Its documentation and this specification are updated if a decision
    changed.
8.  The task report required by `ROADMAP.md` has been delivered and the
    owner has said "approved".

------------------------------------------------------------------------

## 23. Document Map

| File | Purpose |
|---|---|
| `SPEC.md` | Product and technical source of truth (this file) |
| `ROADMAP.md` | Ordered tasks, verification, development loop, approval gates |
| `docs/CONTENT_SCHEMA.md` | Content file format, ID rules, validation rules (awaiting owner approval) |

------------------------------------------------------------------------

**End of specification.**
