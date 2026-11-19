# AI chat client (Task 11)

Flutter side of `POST /v1/chat` (backend: `backend/docs/AI_POLICY.md`,
`backend/docs/ABUSE_PROTECTION.md`).

## Behaviour

- **Book-only indicator** on every conversation and the **scope** (whole book / one
  saint) always visible. The scope of a conversation never changes silently:
  "تغيير النطاق" explains that it starts a *new* conversation, which then replaces the
  current screen. The old conversation stays unchanged.
- The scope travels in its own request fields (`mode`, `scope`) from the stored
  conversation. Text in earlier messages can never widen it.
- **Context sent with each question** (`domain/context_window.dart`): the question plus
  at most 6 recent delivered messages within 3000 characters (user messages capped at
  1000, assistant at 500); failed/pending messages are never sent. Limits are inside the
  backend's (20 messages / 2000 each / 8000 total).
- **Rendering by block type:** quotation (highlighted, "اقتباس من الكتاب"), paraphrase
  ("تلخيص لما في الكتاب"), inference ("استنتاج حذر (ليس نصًا من الكتاب)"). Each block
  shows source chips (saint › section · page); tapping one opens the reader at that
  paragraph. Pastoral note, refusal, and safety replies have their own styles.
  A refusal for a saint outside the scope offers "اسأل في كل الكتاب" (new conversation).
- **Failure states:** offline, timeout, rate limited (with wait time), temporarily
  unavailable (spend cap / kill switch), app not verified, server error, bad response,
  not configured, reply could not be saved. The typed question stays in the input box;
  nothing is saved until an answer arrives, so a failed send leaves no half
  conversation. Retry and dismiss are on the banner.
- **Stored replies** keep their structure (`metaJson`, with the book's content version),
  so old conversations read offline exactly as they appeared.
- **Report this answer:** confirmation screen shows exactly what would be sent (answer,
  question, cited paragraph ids, content version, provider/model, reason, optional
  note) and states that no other message is sent. Sending is **not wired yet** (Task
  12a): the screen says so and sends nothing.

## Configuration (build time)

| `--dart-define` | meaning |
|---|---|
| `CHAT_API_BASE_URL=https://…` | backend address. Empty: debug builds use `http://10.0.2.2:3000` (emulator → host); release builds show "not configured". |
| `ATTESTATION_TEST_TOKEN=…` | dev/CI only; matches backend `ATTESTATION_MODE=test` |

The main manifest now declares `INTERNET`. Cleartext HTTP is allowed in the **debug**
manifest only; release must use https.

`installationId` is a random id kept in a small file in app-support storage (rate-limit
key only, not a login). `requestId` is fresh per question.

## Not done / needs a decision

- **Real Play Integrity token on the device.** The backend verifies it; the app has a
  provider interface (`AttestationProvider`) but no Play Integrity plugin yet. It needs
  the app published to a Play track and a plugin choice. Until then: `NoAttestation`
  (works with backend `off`) or the test token. A production backend rejects both.
- Unverified on a device: Iconsax/flag icon rendering, RTL polish of the chat bubbles.
