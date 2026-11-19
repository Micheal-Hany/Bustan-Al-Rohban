# Abuse protection and spending controls (Task 10d)

SPEC §7.5. No accounts exist, so none of this is user authentication.

## Order of checks (`POST /v1/chat`, `POST /v1/reports`)

1. Body limit 64 KB (413 `request_too_large`); message count/length limits (400).
2. **Per-IP rate limit** (before parsing and before any Google call).
3. **Attestation** (403 `attestation_required` / `attestation_failed`; 503
   `attestation_unavailable` when Google cannot be reached: fail closed).
4. **Per-installation rate limit** (`installationId` body field, 16–64 chars). The id
   is client-supplied, so the IP limit always applies as well; omitting the id only
   leaves the IP limit.
5. Retrieval / safety (free paths).
6. **Spend guard** before every model call, retries included.

429 bodies carry `retryAfterSeconds` and a `Retry-After` header.

## Spend cap and kill switch

- Daily total (UTC day, in memory) of estimated model cost. At the cap, model calls
  return 503 `temporarily_unavailable` (the app shows a friendly message).
- A call with unknown cost (no usage, unpriced model, timeout) is charged
  `UNKNOWN_COST_USD`, so missing data cannot bypass the cap.
- `AI_KILL_SWITCH=true` refuses all model calls (change needs a restart).
- `MAX_CONCURRENT_MODEL_CALLS` bounds in-flight calls (503 `busy`), limiting overshoot.
- Safety replies and retrieval refusals call no model and stay available (the
  self-harm referral must never be switched off by a budget).

## Attestation modes

| mode | use |
|---|---|
| `off` | local development only; **refused in production** |
| `test` | CI/emulator: backend accepts exactly `ATTESTATION_TEST_TOKEN` (header-free, in the body field `attestationToken`). **Refused in production** |
| `play_integrity` | production: Google `decodeIntegrityToken` via a service-account key |

Client contract for `play_integrity` (to implement in Task 11): `requestId` is required;
nonce = `base64url(sha256(requestId))` without padding; send the token as
`attestationToken`. The backend checks package name, nonce, token age
(`ATTESTATION_MAX_AGE_SECONDS`), `PLAY_RECOGNIZED`, `MEETS_DEVICE_INTEGRITY`, and an
optional signing-certificate allow-list. Sideloaded or debug builds fail it by design:
use `test` mode for those environments only.

## Report endpoint

`POST /v1/reports` (Task 12a) validates a strict schema (no conversation history, no
unknown fields), applies the same limits and attestation, stores the report and returns
`202 {reportId, stored:true}`. Stored fields only: id, received time, reason, note,
answer text, question, cited paragraph ids, content version, provider, model. NOT
stored: installation id, IP, attestation token, conversation. Without `REPORTS_FILE`
the endpoint answers 503 `reports_unavailable` and keeps nothing. Storage is an
append-only JSON-lines file (`npm run reports:list` to read); PostgreSQL (SPEC 12.4)
can replace it behind the `ReportStore` interface. Retention period: owner decision.

## Residual risks (owner to accept or fix)

1. **Counters are in memory and per instance.** A restart resets the daily total, and
   running two instances doubles the effective cap. Run one instance, and ALSO set a
   hard monthly/daily budget limit in the OpenAI and Google consoles: that is the real
   backstop.
2. Play Integrity code is **tested with mocks only**; it has not run against Google
   (needs a Play-published app, a Cloud project and a service account).
3. A determined attacker rotating IPs can still spend up to the daily cap; the cap
   bounds the loss, it does not prevent it.
4. All numeric limits are proposals (SPEC §19 decision 5 is open).
