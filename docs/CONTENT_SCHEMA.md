# Content Schema --- Bustan Al-Rohban

**Document:** `docs/CONTENT_SCHEMA.md`\
**Schema version:** `1`\
**Status:** **APPROVED by the owner on 2026-11-15** (all 7 items in section 8, no changes). The real book files may now be prepared in the authoring format.\
**Used by:** Task 1 (loader, validator, converter), Task 7 (insights), Task 10 (backend corpus), Task 13 (real import).

The owner supplies the book as plain text files (section 2). A converter
(built in Task 1) turns them into the JSON in section 3. The same JSON is
shipped in the app and indexed by the backend, so both sides always cite
the same paragraphs.

---

## 1. Principles

- **Original text is never changed** by the converter, the validator, or the app. No trimming of words, no normalization, no diacritic removal in stored text. (Only leading/trailing whitespace of a paragraph is trimmed, and line breaks inside a paragraph are kept as written.)
- **Stable IDs.** Once an ID is published it is never changed or reused. Bookmarks, progress, citations, and reports depend on it.
- **Page numbers are never guessed.** Unknown means `null`.
- **Paragraph is the smallest citable unit.** Chat citations, bookmarks, search hits, and insights all point to paragraph IDs.
- **FAKE fixtures are flagged** with `"fixture": true` and must never ship.

## 2. Authoring format (what the owner prepares)

One UTF-8 `.txt` file per saint, named `<order>-<saint-slug>.txt`, for example `001-anba-example.txt`.

Rules:

- A line starting with `@saint` begins the file's header block. Header lines are `key: value`.
- A line starting with `## ` starts a section; the rest of the line is the section title exactly as printed in the book.
- `[p.N]` on its own line means "the text below starts on printed page N". It applies until the next `[p.N]`. If the page is unknown, write `[p.?]`.
- A **blank line separates paragraphs**. Single line breaks inside a paragraph are kept.
- A line starting with `### ` is a heading paragraph (sub-heading inside a section). It is stored as a paragraph with `kind: "heading"`.
- Lines starting with `#note ` are **owner notes** (extraction doubts, corrections needed). They are not book text; they go to the content report and are never shipped.
- Do not add summaries or commentary in these files. Insights are separate (section 4).

Example (**FAKE**, for format illustration only):

```text
@saint
id: saint-fake-one
title: [تجريبي] القديس الأول
aliases: القديس الأول; فيك ون
fixture: true

## [تجريبي] القسم الأول
[p.1]
هذه فقرة تجريبية أولى. ليست من الكتاب.

هذه فقرة تجريبية ثانية. ليست من الكتاب.
[p.2]
### [تجريبي] عنوان فرعي
هذه فقرة تجريبية ثالثة تبدأ في الصفحة الثانية.
#note تحقق من الصفحة في الطبعة الورقية

## [تجريبي] القسم الثاني
[p.?]
هذه فقرة تجريبية رابعة بلا رقم صفحة معروف.
```

Header keys: `id` (optional: generated from order and title if omitted, then **frozen** in a registry file, see section 5), `title` (required), `aliases` (optional, `;` separated, used for backend scope and search), `fixture` (optional, default false).

Book-level metadata is in one extra file `book.txt`:

```text
@book
id: bustan-al-rohban
title: بستان الرهبان
language: ar
edition: <title/author of the edition>
publisher: <publisher>
year: <year>
attribution: <required attribution text>
rights: owner-confirmed
```

## 3. JSON output

### 3.1 Layout

```text
assets/content/
  manifest.json
  saints/
    saint-<slug>.json
  insights/
    saint-<slug>.insights.json
```

Per-saint files let the app load one saint at a time instead of the whole book.

### 3.2 `manifest.json`

```json
{
  "schemaVersion": 1,
  "contentVersion": 1,
  "bookId": "bustan-al-rohban",
  "title": "بستان الرهبان",
  "language": "ar",
  "fixture": false,
  "edition": {
    "title": "...", "author": "...", "publisher": "...", "year": "...",
    "attribution": "..."
  },
  "saints": [
    {
      "id": "saint-<slug>",
      "title": "...",
      "order": 1,
      "aliases": ["..."],
      "file": "saints/saint-<slug>.json",
      "sectionCount": 3,
      "paragraphCount": 120
    }
  ],
  "contentHash": "sha256:..."
}
```

`contentHash` covers all saint files and lets the app and backend prove they hold the same corpus.

### 3.3 Saint file

```json
{
  "schemaVersion": 1,
  "id": "saint-<slug>",
  "title": "...",
  "order": 1,
  "aliases": ["..."],
  "sections": [
    {
      "id": "sec-<slug>-001",
      "title": "...",
      "order": 1,
      "pageStart": 1,
      "pageEnd": 2,
      "paragraphs": [
        {
          "id": "p-000001",
          "order": 1,
          "kind": "body",
          "page": 1,
          "text": "..."
        }
      ]
    }
  ]
}
```

Fields:

| Field | Type | Notes |
|---|---|---|
| `id` | string | Matches `^[a-z0-9]+(-[a-z0-9]+)*$` for saints/sections; `^p-\d{6}$` for paragraphs. Unique across the **whole book**. |
| `order` | int | 1-based, contiguous within the parent. Display order only; never used as identity. |
| `kind` | `"body"` or `"heading"` | Default `body`. |
| `page` | int or `null` | Printed page where the paragraph starts. `null` if unknown. |
| `pageStart`/`pageEnd` | int or `null` | Derived from paragraphs; `null` if any page in the section is unknown. |
| `text` | string | Exact original text, non-empty. |

Sub-sections beyond one level are not used in V1. If the book needs them, they are added with a schema version bump (section 7).

### 3.4 Search/AI derived data (not source of truth)

The normalized search text and any backend chunking are **derived** at build/index time from `text`. They are never stored in the saint files.

## 4. Insights (separate files)

Insights are editorial or AI-assisted and must be visually distinct. They never live inside the original text files.

```json
{
  "schemaVersion": 1,
  "saintId": "saint-<slug>",
  "contentVersion": 1,
  "insights": [
    {
      "id": "ins-<slug>-001",
      "sectionId": "sec-<slug>-001",
      "summary": "...",
      "keyPoints": ["..."],
      "spiritualLessons": ["..."],
      "keywords": ["..."],
      "supportingParagraphIds": ["p-000001", "p-000002"],
      "origin": "ai_draft",
      "reviewStatus": "approved",
      "reviewedBy": "owner",
      "reviewedAt": "2026-11-20",
      "fixture": false
    }
  ]
}
```

- `origin`: `ai_draft` or `human`.
- `reviewStatus`: `draft`, `approved`, or `rejected`. **Only `approved` insights are shown in release builds.**
- `supportingParagraphIds` must exist in the same saint file.

## 5. ID rules and the ID registry

- Saint and section IDs are slugs. Paragraph IDs are `p-` plus a six-digit number assigned **once**, in the order first imported.
- A committed `content/id-registry.json` maps each paragraph's first-import fingerprint (hash of its original text plus its section ID) to its ID, so re-importing after a typo fix **keeps the same ID**. New paragraphs get new numbers; removed paragraphs' numbers are retired and never reused.
- If a paragraph's text is edited, the converter reports "changed paragraph keeps ID?" for the owner to confirm. A silent change is not allowed.

## 6. Validation rules (Task 1 must enforce)

Errors (block the build):

1. Malformed JSON or a file that does not match the schema; the message names the file, path, and expected type.
2. Duplicate IDs anywhere in the book.
3. Missing required fields (`id`, `title`, `order`, paragraph `text`).
4. Empty or whitespace-only paragraph text.
5. `order` not contiguous or not starting at 1 within a parent.
6. Manifest entry points to a missing file, or counts do not match.
7. Insight references a missing section or paragraph ID.
8. `page` is not a positive integer or `null`, or pages decrease inside a saint (reported as an error unless the line is marked with an `#note` explaining it).
9. `fixture: true` content present while building a release.
10. `contentHash` mismatch between app and backend corpora.

Warnings (appear in the content report; the owner decides):

1. Paragraph with unknown page (`null`).
2. Very long paragraph (above a configurable length), which may need a split.
3. Suspicious characters (Latin letters, private-use characters, repeated punctuation, broken ligature forms, stray `?`).
4. Duplicated page headers/footers found as paragraphs.
5. Section without a title.
6. Saint without aliases.
7. Owner `#note` lines present (listed verbatim).

The **content report** is a generated Markdown file listing counts, all warnings, and all errors, for the owner to work through.

## 6.1 Required Task 1 tests (preview)

- Valid FAKE fixture loads and preserves order.
- Each error rule above has a failing-fixture test with an understandable message.
- Authoring text parses to the expected JSON (round trip).
- Original text is byte-identical after conversion (including diacritics).
- `[p.?]` produces `null`, never a guessed number.
- Re-import keeps existing paragraph IDs.

## 7. Versioning and migration

- `schemaVersion` changes only when the structure changes. Any change needs a SPEC update and a written migration note.
- `contentVersion` increases when book text or insights change. The app stores which `contentVersion` a bookmark or conversation scope was created under.
- Because identity is the ID, re-ordering or re-splitting sections never breaks bookmarks, as long as paragraph IDs are kept.

## 8. Owner decisions (approved 2026-11-15)

Please reply with "approved" or with changes to any item:

1. **Authoring format** (section 2): one `.txt` file per saint with `@saint`, `## section`, `[p.N]`, blank-line paragraphs, `### heading`, `#note`. OK?
2. **Granularity:** paragraph is the citable unit; sections are one level under a saint (no sub-sections in V1). Does the real book need deeper levels?
3. **Page numbers:** printed page numbers of your edition, `[p.?]` when unknown. OK?
4. **Saint aliases:** you list name variants per saint (for example the Arabic and Coptic spellings), so scoped chat and search resolve them. OK?
5. **ID registry** (section 5): paragraph IDs frozen on first import. OK?
6. **Insights stored separately**, only `approved` insights shown in release builds. OK?
7. **Book metadata** you will provide in `book.txt`: edition, publisher, year, attribution. OK?

After approval, this file's status changes to "Approved" with the date, and Task 1 implements it exactly.
