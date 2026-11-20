# Release checklist (Task 12b)

Status: **DRAFT — nothing here has been run on a device yet.** Cells marked ☐ are
for the owner/tester to fill in. Automated checks are listed first; they do not
replace the manual passes.

## 1. Automated checks

```bash
flutter analyze
flutter test
flutter build apk --release
# secret scan of the source AND the built APK (Windows 10+ tar extracts zip)
mkdir build\apk_scan
tar -xf build\app\outputs\flutter-apk\app-release.apk -C build\apk_scan
dart run tool/secret_scan.dart build/apk_scan lib assets android/app/src pubspec.yaml
cd backend && npm test -- --runInBand && npm run lint && npm run eval
```

| Check | Where |
|---|---|
| Palette contrast ≥ 4.5:1 (light and dark) | `test/app/dark_mode_test.dart` |
| Appearance choice saved, followed, system default | `test/app/dark_mode_test.dart`, `test/features/settings/` |
| 48dp tap targets, labelled controls, no overflow at 2.0 font scale — 7 screens × 2 themes | `test/app/accessibility_test.dart` |
| Font licences (OFL 1.1 file per family, no unregistered fonts) | `test/app/font_licence_test.dart` |
| Secret scanner + repo scan | `test/tool/secret_scan_test.dart`, `tool/secret_scan.dart` |

## 2. Font licences (verified)

Amiri (Regular, Bold) and Tajawal (Regular, Medium, Bold): the SIL Open Font License 1.1 text
is bundled (`assets/fonts/OFL-*.txt`) and each `.ttf` carries the OFL 1.1 notice in its own
name table. OFL permits embedding and redistribution in an app. Note: the Tajawal files say
"(c) 2017 Boutros International", the bundled licence file says "2018" — harmless, but the owner
may wish to align the file text with the fonts. Show the licences in the app (about screen) only
if the owner wants; OFL does not require on-screen display, only that the licence travel with
the font files.

## 3. Release blockers found (owner decisions)

1. **Application ID** is still `com.example.bustan_al_rohban`. Google Play rejects `com.example.*`.
   The ID can never change after publishing. Owner: choose it (e.g. a reverse-domain of
   coptic-treasures.com).
2. **Signing key.** `android/app/build.gradle.kts` now reads `android/key.properties`
   (git-ignored: `storeFile`, `storePassword`, `keyAlias`, `keyPassword`). Without it the build is
   signed with the debug key and prints a warning. Owner creates and safely backs up the upload key.
3. **FAKE content ships in the asset list** until Task 13 (by design). Do not publish before it.
4. **Play Integrity client** is not in the app (backend verification is mocked-only); production
   chat needs it (see `docs/CHAT_CLIENT.md`).
5. App name in the launcher is now `بستان الرهبان`; confirm.

## 4. Android compatibility matrix (fill in)

Install the **release** APK. Minimum recommended coverage: oldest supported Android, a current
one, a small phone, a large phone/tablet, and one with a non-Google Arabic TTS engine.

| Device | Android | Screen | Installs | Offline read | Search | TTS ar | Chat online | Dark | TalkBack | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| ☐ | | | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | |
| ☐ | | | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | |
| ☐ | | | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | |

`minSdk` comes from the Flutter SDK default (`flutter.minSdkVersion`); record the real number
from `flutter build apk --release -v` or `android/app/build.gradle.kts` resolution and state the
oldest Android you actually tested.

## 5. TalkBack script (Arabic, one pass per screen)

Enable TalkBack with the system language Arabic. For each screen confirm: reading order follows
the visual RTL order; every button announces a meaningful Arabic label (no "button" alone);
state is announced (selected chip, disabled button); nothing focusable is unlabelled.

1. Home: four tiles announce title and "double tap to activate".
2. Library → saint → section list → reader: paragraph text is read in order; page references are
   announced; text-size and bookmark controls are labelled.
3. Search: field has a label; results announce title and location; empty state is announced.
4. Bookmarks: each item announces its place; delete is reachable and confirmed.
5. Chat: input labelled; "send" labelled; answer blocks announce type (quotation / paraphrase /
   inference); source references reachable; "report this answer" reachable; first-send notice
   readable and its buttons labelled; errors announced.
6. Settings: font size, line spacing chips, appearance chips announce selected state.
7. Privacy screen: headings navigable.

Result: ☐ pass ☐ issues (list) — tester/date: ____

## 6. Dark mode (manual)

Appearance in Settings: حسب الجهاز (default, follows the phone) / فاتح / داكن.

☐ Switching is immediate on every screen (home, library, reader, search, bookmarks, chat, settings, privacy)
☐ Reader text and the read-aloud highlight are comfortable at night
☐ Quotation blocks in chat are distinct from paraphrase blocks
☐ No white flashes on screen change; keyboard and dialogs are dark
☐ Kill and reopen the app: the choice persists
☐ Phone set to dark + app on "system": app is dark; flip the phone setting: app follows

## 7. Online/offline verification matrix

| Feature | Offline (airplane mode) | Online | Result |
|---|---|---|---|
| Library, reader | works | works | ☐ |
| Local search | works | works | ☐ |
| Bookmarks, progress, reading prefs, appearance | works | works | ☐ |
| Old chat history readable | works | works | ☐ |
| Send chat question | clear offline error, typed text kept | answer with sources | ☐ |
| Report an answer | "not available now", nothing sent | confirmation | ☐ |
| TTS | only if an offline Arabic voice exists | works | ☐ |
| App start with no network | no spinner hang, no crash | – | ☐ |

## 8. Sign-off

Owner: ____________ Date: ________ ☐ Matrix reviewed ☐ Blockers in §3 resolved or accepted
