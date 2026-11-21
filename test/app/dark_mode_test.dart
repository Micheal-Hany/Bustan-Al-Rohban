import 'package:bustan_al_rohban/app/app.dart';
import 'package:bustan_al_rohban/app/theme/app_theme.dart';
import 'package:bustan_al_rohban/features/settings/domain/reading_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/library/library_test_support.dart';
import 'contrast.dart';

const _aa = 4.5;

void main() {
  group('palette contrast (WCAG AA, 4.5:1 for text)', () {
    for (final entry in {
      'light': AppTheme.light(),
      'dark': AppTheme.dark(),
    }.entries) {
      final theme = entry.value;
      final scheme = theme.colorScheme;
      final colors = theme.extension<BustanColors>()!;

      test('${entry.key}: text on page, card and quote surfaces', () {
        expect(contrastRatio(scheme.onSurface, scheme.surface),
            greaterThanOrEqualTo(_aa));
        expect(contrastRatio(colors.ink, scheme.surface),
            greaterThanOrEqualTo(_aa));
        expect(contrastRatio(colors.ink, colors.card),
            greaterThanOrEqualTo(_aa));
        expect(contrastRatio(colors.ink, colors.quoteSurface),
            greaterThanOrEqualTo(_aa));
        expect(contrastRatio(scheme.onSurface, colors.card),
            greaterThanOrEqualTo(_aa));
      });

      test('${entry.key}: accent (titles, icons) and buttons', () {
        expect(contrastRatio(colors.accent, scheme.surface),
            greaterThanOrEqualTo(_aa));
        expect(contrastRatio(colors.accent, colors.card),
            greaterThanOrEqualTo(_aa));
        expect(contrastRatio(colors.accent, colors.quoteSurface),
            greaterThanOrEqualTo(_aa));
        expect(contrastRatio(scheme.onPrimary, scheme.primary),
            greaterThanOrEqualTo(_aa));
      });

      test('${entry.key}: text stays readable on the read-aloud highlight',
          () {
        final bg = over(colors.highlight, scheme.surface);
        expect(contrastRatio(colors.ink, bg), greaterThanOrEqualTo(_aa));
      });
    }

    test('hero banner text is readable on its gradients', () {
      for (final stop in [...AppTheme.heroLight, ...AppTheme.heroDark]) {
        expect(contrastRatio(Colors.white, stop), greaterThanOrEqualTo(_aa));
        expect(contrastRatio(AppTheme.goldBright, stop),
            greaterThanOrEqualTo(_aa));
      }
      expect(contrastRatio(AppTheme.ink, AppTheme.goldBright),
          greaterThanOrEqualTo(_aa));
    });
  });

  group('themes', () {
    test('dark theme is dark Material 3 with the Arabic fonts', () {
      final t = AppTheme.dark();
      expect(t.brightness, Brightness.dark);
      expect(t.useMaterial3, isTrue);
      expect(t.textTheme.bodyLarge?.fontFamily, AppTheme.fontFamily);
      expect(t.textTheme.bodyLarge?.height, 1.8);
    });

    test('BustanColors falls back to the light values without the extension',
        () {
      expect(ThemeData().extension<BustanColors>(), isNull);
    });
  });

  group('app follows the saved preference', () {
    Future<Brightness> pump(
      WidgetTester tester,
      PrefsStore store, {
      Brightness platform = Brightness.light,
    }) async {
      tester.platformDispatcher.platformBrightnessTestValue = platform;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BustanApp(
        libraryRepository: repoFor(probeFor(twoSaintBook())),
        prefsStore: store,
      ));
      await tester.pumpAndSettle();
      return Theme.of(tester.element(find.byKey(const Key('home-screen'))))
          .brightness;
    }

    testWidgets('system: follows a dark phone', (tester) async {
      expect(await pump(tester, InMemoryPrefsStore(), platform: Brightness.dark),
          Brightness.dark);
    });

    testWidgets('system: follows a light phone', (tester) async {
      expect(await pump(tester, InMemoryPrefsStore()), Brightness.light);
    });

    testWidgets('saved dark wins over a light phone', (tester) async {
      final store = InMemoryPrefsStore();
      await store.save(const ReadingPrefs(themePreference: ThemePreference.dark));
      expect(await pump(tester, store), Brightness.dark);
    });

    testWidgets('saved light wins over a dark phone', (tester) async {
      final store = InMemoryPrefsStore();
      await store.save(const ReadingPrefs(themePreference: ThemePreference.light));
      expect(await pump(tester, store, platform: Brightness.dark),
          Brightness.light);
    });

    testWidgets('choosing dark in Settings switches at once and is saved',
        (tester) async {
      final store = InMemoryPrefsStore();
      await pump(tester, store);
      await tester.tap(find.byKey(const Key('nav-settings')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('settings-theme-dark')));
      await tester.tap(find.byKey(const Key('settings-theme-dark')));
      await tester.pumpAndSettle();
      expect(
          Theme.of(tester.element(find.byKey(const Key('settings-screen'))))
              .brightness,
          Brightness.dark);
      expect((await store.load()).themePreference, ThemePreference.dark);

      await tester.tap(find.byKey(const Key('settings-theme-light')));
      await tester.pumpAndSettle();
      expect(
          Theme.of(tester.element(find.byKey(const Key('settings-screen'))))
              .brightness,
          Brightness.light);
    });

    testWidgets('home cards use the dark card color in dark mode',
        (tester) async {
      final store = InMemoryPrefsStore();
      await store.save(const ReadingPrefs(themePreference: ThemePreference.dark));
      await pump(tester, store);
      final ctx = tester.element(find.byKey(const Key('home-screen')));
      expect(BustanColors.of(ctx).card, BustanColors.dark.card);
    });
  });
}
