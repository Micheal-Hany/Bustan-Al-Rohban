import 'package:bustan_al_rohban/app/app.dart';
import 'package:bustan_al_rohban/features/settings/domain/reading_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../features/ai_chat/history/chat_test_support.dart';
import '../features/library/library_test_support.dart';

/// Automated accessibility checks that run in light and dark mode. They
/// cannot replace a TalkBack pass on a device (docs/RELEASE_CHECKLIST.md).
const _readerPath = '/library/book/saints/saint-a/sections/sec-a-001';

Future<void> _pump(
  WidgetTester tester,
  ThemePreference theme, {
  double fontScale = 1.0,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = fontScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final store = InMemoryPrefsStore();
  await store.save(ReadingPrefs(themePreference: theme));
  await tester.pumpWidget(BustanApp(
    libraryRepository: repoFor(probeFor(twoSaintBook())),
    prefsStore: store,
    chatApi: FakeChatApi(),
  ));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, String screen) async {
  switch (screen) {
    case 'home':
      break;
    case 'reader':
      final ctx = tester.element(find.byKey(const Key('home-screen')));
      GoRouter.of(ctx).push(_readerPath);
      await tester.pumpAndSettle();
    default:
      await tester.tap(find.byKey(Key('nav-$screen')));
      await tester.pumpAndSettle();
  }
}

const _screens = ['home', 'library', 'search', 'bookmarks', 'chat', 'settings', 'reader'];

void main() {
  for (final theme in [ThemePreference.light, ThemePreference.dark]) {
    for (final screen in _screens) {
      group('${theme.name} / $screen', () {
        testWidgets('tap targets are at least 48dp', (tester) async {
          final handle = tester.ensureSemantics();
          await _pump(tester, theme);
          await _open(tester, screen);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          handle.dispose();
        });

        testWidgets('every tappable control has a label', (tester) async {
          final handle = tester.ensureSemantics();
          await _pump(tester, theme);
          await _open(tester, screen);
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          handle.dispose();
        });

        testWidgets('no overflow at the largest system font size (2.0)',
            (tester) async {
          await _pump(tester, theme, fontScale: 2.0);
          await _open(tester, screen);
          expect(tester.takeException(), isNull);
        });
      });
    }
  }
}
