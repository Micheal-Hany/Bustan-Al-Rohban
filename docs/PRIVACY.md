# Privacy: behaviour, evidence and decisions (Task 12a)

The user-facing text is `lib/features/privacy/domain/privacy_text.dart` (screen:
Settings › الخصوصية والبيانات, and a link in the chat list). **The owner approves the
wording.** This page maps each statement to the code that makes it true, so it can be
re-checked whenever behaviour changes.

| Statement in the notice | Where it is enforced / tested |
|---|---|
| Reading data (bookmarks, progress, font prefs) stays on the device | no network code outside the two chat clients: `test/privacy/no_telemetry_test.dart` ("the only network code…") |
| Chat history is local, in a separate file excluded from Android backup | `chat/chat.sqlite`, `android/app/src/main/res/xml/backup_rules.xml` + `data_extraction_rules.xml` (Task 9); delete one/all in the chat list |
| History is deleted with uninstall / clear data / in-app delete | Android behaviour; `chat_history_flow_test.dart` for in-app delete |
| A question + bounded recent context + scope + random install id is sent | `domain/context_window.dart`, `domain/chat_api.dart` (`ChatRequest.toJson`); tests in `chat_domain_test.dart`, `http_chat_api_test.dart` |
| HTTPS | release builds have no cleartext exception (only `android/app/src/debug`); base URL set by `CHAT_API_BASE_URL` |
| Server stores no question/answer/history; logs have no text | backend `protection.spec.ts` ("privacy-safe logging and no storage"), `app.spec.ts` (only the report store writes to disk, no DB dependency) |
| IP used only transiently in memory for rate limits | `backend/src/protection/rate-limiter.ts`; report records hold no IP (`reports.spec.ts`) |
| Provider processes text under its own terms | `backend/src/providers/*` (OpenAI or Gemini chosen by config) |
| Google Play Integrity may be used | `backend/src/protection/attestation.ts` |
| Report: shown exactly before sending; no history; no install id stored; not for training | `report_screen.dart` + `conversation_screen_test.dart`; backend `reports.spec.ts` |
| No accounts, ads, analytics, or external crash reporting | `test/privacy/no_telemetry_test.dart` (pubspec, lockfile, Android build files, imports); backend `reports.spec.ts` (no telemetry dependency) |
| First-send notice (once) | `chat_notice_dialog.dart`; `privacy_flow_test.dart` |

## Crash reporting: decision for Version 1 = none

No crash-reporting or analytics SDK is included. Reasons: SPEC 14.3 forbids capturing
chat text or reading content, the owner has not asked for one, and every SDK adds a
disclosure (Play Data Safety) and a processor. Consequence: crashes are only visible
from Play Console's built-in Android vitals (collected by Google Play, not by the app)
and from user reports. The automated check fails if a telemetry package or Gradle
plugin appears, so any future addition must pass a privacy review first.
**Owner: confirm or change this decision.**

## Open items for the owner

1. Approve the privacy wording (Arabic) and the first-send notice.
2. Provide a **privacy-contact** (email) and a **public privacy-policy URL** (Play
   requires a URL). The screen hides the contact line until `privacyContact` is set.
3. **Provider data handling:** check and record the retention/training settings of the
   chosen provider (OpenAI API or Gemini API; paid vs free tiers differ). The notice
   currently says only that the provider processes the text under its own terms.
4. **Report retention period** (how long reports are kept) and who reviews them.
5. Decide whether report storage should move from the JSON-lines file to PostgreSQL.
6. Real Play Integrity client in the app (Task 11 note), then the production switch.
