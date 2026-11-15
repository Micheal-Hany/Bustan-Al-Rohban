import 'package:bustan_al_rohban/app/app.dart';
import 'package:bustan_al_rohban/app/router/app_router.dart';
import 'package:bustan_al_rohban/app/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('router config (unit)', () {
    test('declares every expected route path once', () {
      expect(AppRoutes.all.toSet().length, AppRoutes.all.length);
      expect(
        AppRoutes.all,
        containsAll([
          '/',
          '/library',
          '/search',
          '/bookmarks',
          '/chat',
          '/settings',
        ]),
      );
    });
  });

  group('app boot', () {
    testWidgets('boots to the home screen without network', (tester) async {
      await tester.pumpWidget(const BustanApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-screen')), findsOneWidget);
      expect(find.text(AppStrings.appTitle), findsWidgets);
    });

    testWidgets('home shows all navigation entries', (tester) async {
      await tester.pumpWidget(const BustanApp());
      await tester.pumpAndSettle();

      for (final key in [
        'nav-library',
        'nav-search',
        'nav-bookmarks',
        'nav-chat',
        'nav-settings',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
    });

    testWidgets('can open each placeholder screen and go back', (tester) async {
      final cases = {
        'nav-library': 'library-screen',
        'nav-search': 'search-screen',
        'nav-bookmarks': 'bookmarks-screen',
        'nav-chat': 'chat-screen',
        'nav-settings': 'settings-screen',
      };

      await tester.pumpWidget(const BustanApp());
      await tester.pumpAndSettle();

      for (final entry in cases.entries) {
        await tester.tap(find.byKey(Key(entry.key)));
        await tester.pumpAndSettle();
        expect(find.byKey(Key(entry.value)), findsOneWidget,
            reason: entry.value);
        expect(find.text(AppStrings.underConstruction), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('home-screen')), findsOneWidget);
      }
    });
  });
}
