import 'package:bustan_al_rohban/app/app.dart';
import 'package:bustan_al_rohban/app/strings.dart';
import 'package:bustan_al_rohban/features/settings/domain/reading_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../library/library_test_support.dart';
import '../search/search_test_support.dart';

const _sectionPath = '/library/book/saints/saint-a/sections/sec-a-001';

Future<void> _pumpApp(WidgetTester tester, PrefsStore store) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BustanApp(
    libraryRepository: repoFor(probeFor(searchBook())),
    prefsStore: store,
  ));
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-settings')));
  await tester.pumpAndSettle();
}

Future<void> _openReader(WidgetTester tester) async {
  final ctx = tester.element(find.byKey(const Key('home-screen')));
  GoRouter.of(ctx).push(_sectionPath);
  await tester.pumpAndSettle();
}

TextStyle _previewStyle(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('settings-preview'))).style!;

TextStyle _paragraphStyle(WidgetTester tester, String id) =>
    tester.widget<Text>(find.byKey(Key('para-text-$id'))).style!;

String _label(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const Key('settings-text-scale-label')))
    .data!;

void main() {
  group('Settings screen', () {
    testWidgets('home entry opens the real settings screen', (tester) async {
      await _pumpApp(tester, InMemoryPrefsStore());
      await _openSettings(tester);
      expect(find.byKey(const Key('settings-screen')), findsOneWidget);
      expect(find.text(AppStrings.underConstruction), findsNothing);
    });

    testWidgets('shows the defaults', (tester) async {
      await _pumpApp(tester, InMemoryPrefsStore());
      await _openSettings(tester);
      expect(_label(tester), '100%');
      expect(_previewStyle(tester).fontSize, 18);
      expect(_previewStyle(tester).height, LineSpacing.normal.height);
      final normal = tester
          .widget<ChoiceChip>(find.byKey(const Key('settings-line-normal')));
      expect(normal.selected, isTrue);
    });

    testWidgets('larger and smaller change the label and the preview',
        (tester) async {
      await _pumpApp(tester, InMemoryPrefsStore());
      await _openSettings(tester);
      await tester.tap(find.byKey(const Key('settings-text-larger')));
      await tester.pumpAndSettle();
      expect(_label(tester), '115%');
      expect(_previewStyle(tester).fontSize, closeTo(18 * 1.15, 0.001));

      await tester.tap(find.byKey(const Key('settings-text-smaller')));
      await tester.tap(find.byKey(const Key('settings-text-smaller')));
      await tester.pumpAndSettle();
      expect(_label(tester), '85%');
    });

    testWidgets('size buttons disable at the limits', (tester) async {
      await _pumpApp(tester, InMemoryPrefsStore());
      await _openSettings(tester);
      for (var i = 0; i < 8; i++) {
        final b = tester.widget<IconButton>(
            find.byKey(const Key('settings-text-larger')));
        if (b.onPressed == null) break;
        await tester.tap(find.byKey(const Key('settings-text-larger')));
        await tester.pumpAndSettle();
      }
      expect(_label(tester), '200%');
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('settings-text-larger')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('line spacing choices change the preview', (tester) async {
      await _pumpApp(tester, InMemoryPrefsStore());
      await _openSettings(tester);
      await tester.tap(find.byKey(const Key('settings-line-relaxed')));
      await tester.pumpAndSettle();
      expect(_previewStyle(tester).height, LineSpacing.relaxed.height);
      await tester.tap(find.byKey(const Key('settings-line-compact')));
      await tester.pumpAndSettle();
      expect(_previewStyle(tester).height, LineSpacing.compact.height);
    });

    testWidgets('reset buttons restore the defaults', (tester) async {
      await _pumpApp(tester, InMemoryPrefsStore());
      await _openSettings(tester);
      await tester.tap(find.byKey(const Key('settings-text-larger')));
      await tester.tap(find.byKey(const Key('settings-line-relaxed')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings-text-reset')));
      await tester.pumpAndSettle();
      expect(_label(tester), '100%');
      expect(_previewStyle(tester).height, LineSpacing.relaxed.height);

      await tester.tap(find.byKey(const Key('settings-reset-all')));
      await tester.pumpAndSettle();
      expect(_previewStyle(tester).height, LineSpacing.normal.height);
    });

    testWidgets('reset buttons are disabled when already at defaults',
        (tester) async {
      await _pumpApp(tester, InMemoryPrefsStore());
      await _openSettings(tester);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('settings-reset-all')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('screen is right-to-left', (tester) async {
      await _pumpApp(tester, InMemoryPrefsStore());
      await _openSettings(tester);
      final ctx = tester.element(find.byKey(const Key('settings-screen')));
      expect(Directionality.of(ctx), TextDirection.rtl);
    });
  });

  group('Persistence', () {
    testWidgets('changes are saved to the store', (tester) async {
      final store = InMemoryPrefsStore();
      await _pumpApp(tester, store);
      await _openSettings(tester);
      await tester.tap(find.byKey(const Key('settings-text-larger')));
      await tester.tap(find.byKey(const Key('settings-line-relaxed')));
      await tester.pumpAndSettle();
      final saved = await store.load();
      expect(saved.textScale, 1.15);
      expect(saved.lineSpacing, LineSpacing.relaxed);
    });

    testWidgets('a restart shows the saved preferences', (tester) async {
      final store = InMemoryPrefsStore();
      await _pumpApp(tester, store);
      await _openSettings(tester);
      await tester.tap(find.byKey(const Key('settings-text-larger')));
      await tester.tap(find.byKey(const Key('settings-text-larger')));
      await tester.tap(find.byKey(const Key('settings-line-compact')));
      await tester.pumpAndSettle();

      // "Restart": drop the app, start a new one on the same store.
      await tester.pumpWidget(const SizedBox());
      await _pumpApp(tester, store);
      await _openSettings(tester);
      expect(_label(tester), '130%');
      expect(_previewStyle(tester).height, LineSpacing.compact.height);
    });
  });

  group('Reader reflects the settings', () {
    testWidgets('saved preferences apply when the reader opens',
        (tester) async {
      final store = InMemoryPrefsStore();
      await store.save(const ReadingPrefs(
        textScale: 1.5,
        lineSpacing: LineSpacing.relaxed,
      ));
      await _pumpApp(tester, store);
      await _openReader(tester);
      final style = _paragraphStyle(tester, 'p-000002');
      expect(style.fontSize, closeTo(18 * 1.5, 0.001));
      expect(style.height, LineSpacing.relaxed.height);
      expect(find.text('150%'), findsOneWidget);
    });

    testWidgets('a change in settings shows in the reader', (tester) async {
      final store = InMemoryPrefsStore();
      await _pumpApp(tester, store);
      await _openSettings(tester);
      await tester.tap(find.byKey(const Key('settings-text-larger')));
      await tester.tap(find.byKey(const Key('settings-line-compact')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await _openReader(tester);
      final style = _paragraphStyle(tester, 'p-000002');
      expect(style.fontSize, closeTo(18 * 1.15, 0.001));
      expect(style.height, LineSpacing.compact.height);
    });

    testWidgets('the reader size buttons change and save the same setting',
        (tester) async {
      final store = InMemoryPrefsStore();
      await _pumpApp(tester, store);
      await _openReader(tester);
      await tester.tap(find.byKey(const Key('text-larger')));
      await tester.pumpAndSettle();
      expect((await store.load()).textScale, 1.15);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await _openSettings(tester);
      expect(_label(tester), '115%');
    });

    testWidgets('a live change while reading updates the text at once',
        (tester) async {
      await _pumpApp(tester, InMemoryPrefsStore());
      await _openReader(tester);
      final before = _paragraphStyle(tester, 'p-000002').fontSize!;
      await tester.tap(find.byKey(const Key('text-larger')));
      await tester.pumpAndSettle();
      expect(_paragraphStyle(tester, 'p-000002').fontSize, greaterThan(before));
    });
  });
}
