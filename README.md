# Bustan-Al-Rohban

Arabic-first Flutter app for reading and studying **بستان الرهبان** (Bustan Al-Rohban): offline library and reader, Arabic search, bookmarks, TTS, prepared insights, and a book-only AI assistant.

Website: https://coptic-treasures.com/

## Project documents

| File | Purpose |
|---|---|
| [`SPEC.md`](SPEC.md) | Product and technical source of truth (v1.2) |
| [`ROADMAP.md`](ROADMAP.md) | Ordered tasks, verification, approval gates (v1.1) |
| [`docs/CONTENT_SCHEMA.md`](docs/CONTENT_SCHEMA.md) | Content file format and validation rules (approved 2026-11-15) |

## Status

Planning complete and content schema approved. No application code yet. Implementation starts only after the owner replies **GO** (see `ROADMAP.md` section 9).

## Task 0 setup (run on your machine)

The code was written without a Flutter toolchain, so it is **unverified** until you run it.

```bash
git pull
flutter create --platforms=android --org com.michaelhany --project-name bustan_al_rohban .
rm -f test/widget_test.dart        # generated sample test, replaced by test/app/*
flutter pub get
flutter analyze
flutter test test/app/app_boot_test.dart
flutter test test/app/rtl_smoke_test.dart
flutter run                        # then follow the manual steps in ROADMAP.md, Task 0
```

If `flutter create` overwrote `pubspec.yaml` or `lib/main.dart`, run `git checkout pubspec.yaml lib/main.dart`.
Optional: add the Arabic font files (see `assets/fonts/README.md`).

## Task 1 (content core) - run on your machine

Unverified until you run it. After `git pull`:

```bash
flutter pub get
flutter analyze
flutter test test/core/content/
flutter test
```

Convert authoring text files to JSON (the same tool you will use for the real book):

```bash
dart run tool/convert_content.dart content_src/fake assets/content content_src/fake/id-registry.json
```

Then `flutter run` (debug) and open "معاينة المحتوى" on the home screen.

## Task 2 (library and navigation) - run on your machine

Unverified until you run it. After `git pull`:

```bash
flutter pub get
flutter analyze
flutter test test/features/library/
flutter test
flutter run   # Library -> book -> saints -> a saint -> a section -> back
```

## Spike S1 (TTS feasibility) - run on your machine

Unverified until you run it. After `git pull`:

```bash
flutter pub get
flutter analyze
flutter test spikes/tts/
flutter test
```

Then follow `docs/TTS_SPIKE.md` on a real Android device (includes a one-time manifest change) and fill in the findings table.

## Task 3 (Arabic reader) - run on your machine

Unverified until you run it. After `git pull`:

```bash
flutter pub get          # adds scrollable_positioned_list
flutter analyze
flutter test test/features/reader/
flutter test
flutter run   # Library -> book -> saints -> a saint -> a section
```

Text size is held in memory in this task; persistence comes in Task 6.

## Task 4 (Arabic local search) - run on your machine

Unverified until you run it. After `git pull`:

```bash
flutter pub get
flutter analyze
flutter test test/core/search/
flutter test test/features/search/
flutter test
flutter run   # Search -> type an Arabic word, with and without diacritics
```

The search index is pure Dart (in memory, built from the installed JSON on first search). A SQLite FTS adapter is deferred to Task 5 and only if the real book needs it.

## Task 5 (bookmarks and reading progress) - run on your machine

Drift needs generated code, which I cannot produce here. After `git pull`:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # creates lib/core/db/app_database.g.dart
git add lib/core/db/app_database.g.dart && git commit -m "Task 5: generated Drift code" && git push
flutter analyze
flutter test test/features/bookmarks/
flutter test test/features/reader/progress/
flutter test test/core/db/
flutter test
flutter run   # bookmark a paragraph, restart the app, open Bookmarks, continue reading
```

`test/core/db/` opens a real SQLite database. If the sqlite3 native library is missing (for example Windows without `sqlite3.dll`), those tests are **skipped with a message**, not failed. To run them, put `sqlite3.dll` (from sqlite.org, 64-bit) next to the Flutter SDK's `dart.exe` or on your PATH. Everything else uses in-memory stores that run the same contract tests as the Drift stores.

If `build_runner` or `pub get` reports a version conflict, paste the message and I will adjust the versions.
