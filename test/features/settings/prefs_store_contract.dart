import 'package:bustan_al_rohban/features/settings/domain/reading_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

/// Behavior every [PrefsStore] must have (in-memory and Drift).
void runPrefsStoreContract(
  String label,
  Future<PrefsStore> Function() create, {
  Object? skip,
}) {
  group('PrefsStore contract: $label', skip: skip, () {
    late PrefsStore store;

    setUp(() async {
      store = await create();
    });

    test('returns defaults when nothing is saved', () async {
      expect(await store.load(), ReadingPrefs.defaults);
    });

    test('saved values are read back', () async {
      await store.save(const ReadingPrefs(
        textScale: 1.5,
        lineSpacing: LineSpacing.relaxed,
      ));
      final p = await store.load();
      expect(p.textScale, 1.5);
      expect(p.lineSpacing, LineSpacing.relaxed);
    });

    test('saving again replaces the earlier values', () async {
      await store.save(const ReadingPrefs(textScale: 1.75));
      await store.save(const ReadingPrefs(
        textScale: 0.85,
        lineSpacing: LineSpacing.compact,
      ));
      final p = await store.load();
      expect(p.textScale, 0.85);
      expect(p.lineSpacing, LineSpacing.compact);
    });

    test('theme preference defaults to system and round-trips', () async {
      expect((await store.load()).themePreference, ThemePreference.system);
      for (final t in ThemePreference.values) {
        await store.save(ReadingPrefs(themePreference: t));
        expect((await store.load()).themePreference, t);
      }
    });

    test('every step and every spacing round-trips', () async {
      for (final scale in ReadingPrefs.textScaleSteps) {
        for (final spacing in LineSpacing.values) {
          await store.save(ReadingPrefs(textScale: scale, lineSpacing: spacing));
          expect(await store.load(),
              ReadingPrefs(textScale: scale, lineSpacing: spacing));
        }
      }
    });
  });
}
