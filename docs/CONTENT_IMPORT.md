# Real content import (Task 13) — procedure and tools

Status: **tooling ready, waiting for the owner's text files.** Nothing here has been run on real text.

## Steps

1. **Owner:** put the extracted text in `content_src/real/` in the authoring format of
   `docs/CONTENT_SCHEMA.md` §2 (`book.txt` + one `NNN-name.txt` per saint). Set `fixture: false`
   in `book.txt`.
2. **Convert** (writes nothing if there are errors):
   `dart run tool/convert_content.dart content_src/real build/real_content content_src/real/id-registry.json 1`
3. **Report:** `dart run tool/content_report.dart build/real_content --release --out build/content_report.md`
   - Validator errors (broken IDs, ordering, counts, hash) must be zero.
   - Quality findings are **warnings for the owner to judge** against the printed book:
     `empty-paragraph`, `replacement-char`, `mojibake`, `presentation-forms`, `invisible-chars`,
     `control-chars`, `private-use-chars`, `tatweel-run`, `punctuation-run`, `space-run`,
     `latin-in-arabic`, `very-short`, `very-long`, `duplicate-text`, `pages-missing`,
     `page-goes-back`, `page-jump`. The tool never edits text.
   - The per-saint table (paragraphs, words, page range) is the basis for the content-size and
     performance budget decision.
4. **Owner corrects the source files**, repeat 2–3 until satisfied. The ID registry keeps paragraph
   IDs stable across re-runs (bookmarks and citations depend on this).
5. **Ship:** copy the converter output over `assets/content/`, remove `assets/content_fixtures/` from
   `pubspec.yaml`, and point the backend `CORPUS_DIR` at the same files (the backend default already
   is `../assets/content`; a deployed server needs the same folder copied).
6. **Gate:** `dart run tool/release_content_check.dart assets/content <backend corpus dir>`
   fails on FAKE content, leftover "[تجريبي]" text, app/backend differences in book id, content
   version, saint list or paragraph ids, and on the invalid-fixture asset still being bundled.
   On a running server compare `GET /health` (`contentVersion`, `fixture`) with the app manifest.
7. **Re-run** `flutter test`, `cd backend && npm test -- --runInBand && npm run lint && npm run eval`.
   Retrieval thresholds (`backend/eval/thresholds.json`, `approvedByOwner: false`) and the stop-word
   list were tuned on FAKE text; re-measure on the real corpus, then the owner approves the numbers.
8. Owner reviews real insights; only approved ones ship (release builds already hide unapproved).

## Runtime gate (already in the app)

A **release** build refuses to open FAKE content (`fixture-in-release` error screen). Debug builds
are unaffected. For device-testing a release APK before the real text arrives, build with
`--dart-define=ALLOW_FIXTURE_IN_RELEASE=true`. The final store build must **not** use that flag.
The backend already refuses a FAKE corpus when `NODE_ENV=production`.
