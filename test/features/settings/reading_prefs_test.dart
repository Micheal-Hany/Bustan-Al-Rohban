import 'package:bustan_al_rohban/features/settings/domain/reading_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingPrefs', () {
    test('defaults are 100% and normal spacing', () {
      expect(ReadingPrefs.defaults.textScale, 1.0);
      expect(ReadingPrefs.defaults.lineSpacing, LineSpacing.normal);
      expect(ReadingPrefs.defaults, const ReadingPrefs());
    });

    test('the default is one of the allowed steps', () {
      expect(ReadingPrefs.textScaleSteps, contains(ReadingPrefs.defaultTextScale));
    });

    test('steps are strictly increasing', () {
      const s = ReadingPrefs.textScaleSteps;
      for (var i = 1; i < s.length; i++) {
        expect(s[i], greaterThan(s[i - 1]));
      }
    });

    test('line spacing values are increasing and comfortable', () {
      expect(LineSpacing.compact.height, lessThan(LineSpacing.normal.height));
      expect(LineSpacing.normal.height, lessThan(LineSpacing.relaxed.height));
      expect(LineSpacing.compact.height, greaterThanOrEqualTo(1.5));
    });

    test('canIncrease and canDecrease at the limits', () {
      expect(const ReadingPrefs(textScale: 2.0).canIncrease, isFalse);
      expect(const ReadingPrefs(textScale: 2.0).canDecrease, isTrue);
      expect(const ReadingPrefs(textScale: 0.85).canDecrease, isFalse);
      expect(const ReadingPrefs(textScale: 0.85).canIncrease, isTrue);
    });

    test('snapTextScale picks the nearest allowed step', () {
      expect(ReadingPrefs.snapTextScale(1.0), 1.0);
      expect(ReadingPrefs.snapTextScale(1.2), 1.15);
      expect(ReadingPrefs.snapTextScale(1.25), 1.3);
      expect(ReadingPrefs.snapTextScale(0.1), 0.85);
      expect(ReadingPrefs.snapTextScale(99), 2.0);
    });

    test('equality and copyWith', () {
      const a = ReadingPrefs(textScale: 1.3, lineSpacing: LineSpacing.relaxed);
      expect(a, const ReadingPrefs(textScale: 1.3, lineSpacing: LineSpacing.relaxed));
      expect(a.copyWith(textScale: 1.0).lineSpacing, LineSpacing.relaxed);
      expect(a.copyWith(lineSpacing: LineSpacing.compact).textScale, 1.3);
      expect(a == a.copyWith(textScale: 1.5), isFalse);
    });
  });

  group('parseReadingPrefs', () {
    test('missing values give defaults', () {
      expect(parseReadingPrefs(), ReadingPrefs.defaults);
    });

    test('valid values are read', () {
      final p = parseReadingPrefs(textScale: '1.5', lineSpacing: 'relaxed');
      expect(p.textScale, 1.5);
      expect(p.lineSpacing, LineSpacing.relaxed);
    });

    test('corrupt values fall back per field', () {
      final p = parseReadingPrefs(textScale: 'abc', lineSpacing: 'wide');
      expect(p, ReadingPrefs.defaults);
      final q = parseReadingPrefs(textScale: '1.3', lineSpacing: 'nonsense');
      expect(q.textScale, 1.3);
      expect(q.lineSpacing, LineSpacing.normal);
    });

    test('an off-step number snaps to a valid size', () {
      expect(parseReadingPrefs(textScale: '1.2').textScale, 1.15);
      expect(parseReadingPrefs(textScale: '50').textScale, 2.0);
      expect(parseReadingPrefs(textScale: '-3').textScale, 0.85);
    });

    test('non-finite numbers fall back to the default', () {
      expect(parseReadingPrefs(textScale: 'NaN').textScale, 1.0);
      expect(parseReadingPrefs(textScale: 'Infinity').textScale, 1.0);
    });
  });

  group('theme preference', () {
    test('defaults to system; unknown stored value falls back to system', () {
      expect(ReadingPrefs.defaults.themePreference, ThemePreference.system);
      expect(parseReadingPrefs(themePreference: 'neon').themePreference,
          ThemePreference.system);
      expect(parseReadingPrefs(themePreference: 'dark').themePreference,
          ThemePreference.dark);
    });

    test('is part of equality and readingIsDefault ignores it', () {
      const dark = ReadingPrefs(themePreference: ThemePreference.dark);
      expect(dark == ReadingPrefs.defaults, isFalse);
      expect(dark.readingIsDefault, isTrue);
      expect(const ReadingPrefs(textScale: 1.3).readingIsDefault, isFalse);
    });
  });
}
