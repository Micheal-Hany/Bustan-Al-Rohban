# Google Play: Data Safety and AI-content disclosure (DRAFT for the owner)

> Draft prepared from the actual behaviour of this repo. **Verify every answer against the
> current Play Console form** (wording and categories change) before submitting.
> Nothing here has been submitted.

## 1. Data Safety form

**Does the app collect or share required user data types?** Yes (when the AI assistant is used).

| Play data type | Collected? | Shared? | Purpose | Notes |
|---|---|---|---|---|
| Messages › Other in-app messages (chat questions) | Yes, transmitted off-device when the user asks | See note A | App functionality | Not stored by our server; processed by the AI provider to answer. Not collected until the user sends a question. |
| App activity › Other user-generated content (reported answer text, optional note) | Yes, only if the user submits a report | No | App functionality / safety review | Stored for owner review; no history, no identifiers |
| Device or other IDs (random installation id) | Yes, sent with chat/report requests | No | Fraud prevention / abuse limits | Random, not tied to a person; not stored by our server beyond in-memory rate limits |
| Approximate location | No | – | – | IP address is processed transiently in memory for rate limits and not stored (some reviewers class IP as "device or other IDs": confirm) |
| Personal info, financial info, health, contacts, photos, files, audio, web history | No | – | – | – |
| Crash logs / diagnostics | No (no SDK in the app) | – | – | Android vitals are collected by Google Play itself |

**Note A (sharing vs service provider):** the AI provider (OpenAI or Google) acts as a
processor to generate the answer. Play's rules allow transfers to service providers
processing on the developer's behalf to be declared as *not shared*, but the provider's
retention/training terms must be checked first (open item 3 in `PRIVACY.md`). Google
Play Integrity is a Google service used to verify the app. **Owner decides the final
declaration.**

**Security practices**
- Data encrypted in transit: Yes (HTTPS; release builds have no cleartext exception).
- Users can request data deletion: chat history is on-device and deletable in-app/by
  uninstall; the server holds no chat data. Reports contain no identifier, so a specific
  user's report cannot be located: state this in the privacy policy.
- Committed to Play Families policy: not applicable unless the app targets children (owner to confirm target audience).

**Data collection is optional?** The AI assistant is optional; reading, search, bookmarks and audio need no data collection.

## 2. AI-Generated Content policy (Play)

| Requirement | Where the app meets it |
|---|---|
| Disclose that content is AI-generated | Chat screen header "إجابات من كتاب بستان الرهبان فقط"; the notice says answers are AI-generated and may err (`privacy_text.dart` › limits) |
| In-app way to report offensive/unsafe AI content | "الإبلاغ عن هذه الإجابة" on every answer → confirmation screen → `/v1/reports` |
| Safeguards | Book-only retrieval, validated citations and verbatim quotes, safety replies for self-harm / medical / confession / personal ascetic questions, spend caps (`backend/docs/AI_POLICY.md`) |
| No claim of official endorsement | Answers are labelled as from the book, not an official church statement |
| Reports reviewed | Owner reviews via `npm run reports:list` (process to be agreed) |

## 3. Store-listing / policy items still needed

- Privacy-policy URL and contact email (owner).
- App access: no login needed; reviewers can use the app without credentials. The AI
  assistant needs the production backend running and Play Integrity configured: give
  reviewers working access or state how to test.
- Content rating questionnaire (religious content, user-generated AI text).
- Target audience and "contains ads: No".
