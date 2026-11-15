# Arabic font (Task 0)

The theme uses the font family name `NotoNaskhArabic` (`lib/app/theme/app_theme.dart`).
Until the font files are added, Flutter falls back to the device font, so the app still runs.

To bundle it (the app must work offline, so do not load fonts from the network):

1. Download **Noto Naskh Arabic** (SIL Open Font License) from Google Fonts.
2. Put `NotoNaskhArabic-Regular.ttf` and `NotoNaskhArabic-Bold.ttf` in this folder.
3. Uncomment the `fonts:` block in `pubspec.yaml`.
4. Run `flutter pub get`.

Final font choice and licence verification are part of Task 12b.
