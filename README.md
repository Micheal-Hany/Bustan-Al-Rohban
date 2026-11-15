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
