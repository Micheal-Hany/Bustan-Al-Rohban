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
          '/content-preview',
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

    testWidgets('the chat entry opens the conversation list and goes back',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const BustanApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('nav-chat')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-screen')), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-screen')), findsOneWidget);
    });
  });
}
