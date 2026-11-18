# Bustan Al-Rohban backend (Task 10a)

Stateless NestJS service: book-only retrieval and refusal. **No LLM, no database, no keys yet** (provider adapters arrive in Task 10c). Design and decisions: `docs/RETRIEVAL.md`.

## Run

Needs Node 20+.

```
cd backend
npm install
npm test -- --runInBand
npm run lint
npm run build
npm start          # http://localhost:3000
```

`npm run start:dev` runs from source. Copy `.env.example` to `.env` to change settings (values are read from real environment variables; set them in your shell). By default it reads the FAKE corpus the app ships (`../assets/content`). With `NODE_ENV=production` it refuses to start on FAKE content.

## Try it (Windows PowerShell)

```powershell
Invoke-RestMethod http://localhost:3000/health

# Scoped to one FAKE saint: only that saint's passages come back
$b = @{ mode='saint_scope'; scope=@{ saintId='saint-fake-one' }; messages=@(@{ role='user'; text='فقرة تجريبية خامسة' }) } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Method Post -Uri http://localhost:3000/v1/retrieve -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($b))

# Naming another saint while scoped: refused (out_of_scope_saint)
# text='ماذا قال القديس الثاني عن فقرة تجريبية؟'

# Unsupported question: refused (insufficient_evidence)
# mode='book_scope', no scope, text='ما هي عاصمة فرنسا؟'
```

Log lines are printed in the terminal running the server: they contain ids and outcome only, never the question text.

## API (debug only until Task 10b)

`GET /health` and `POST /v1/retrieve` (off when `NODE_ENV=production` or `ENABLE_RETRIEVE_ENDPOINT=false`).

Request: `{ mode: 'saint_scope'|'book_scope', scope: { bookId?, saintId?, sectionId? }, messages: [{ role: 'user'|'assistant', text }] (1-20, last is user, <= 2000 chars each, <= 8000 total), requestId?, conversationId? }`.
Response: `{ requestId, status: 'ok', passages[], mentionedSaintIds[], evidence }` or `{ requestId, status: 'refused', reason, message, suggestedSaintIds? }`. Errors: `{ error: { code, message } }` with fixed text.
