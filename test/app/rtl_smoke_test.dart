import 'package:bustan_al_rohban/app/app.dart';
import 'package:bustan_al_rohban/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home screen is right-to-left with Arabic locale',
      (tester) async {
    await tester.pumpWidget(const BustanApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(const Key('home-screen')));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Localizations.localeOf(context).languageCode, 'ar');
  });

  testWidgets('RTL is kept on a pushed screen', (tester) async {
    await tester.pumpWidget(const BustanApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-library')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(const Key('library-screen')));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  test('theme initializes with Material 3 and Arabic-friendly line height', () {
    final theme = AppTheme.light();
    expect(theme.useMaterial3, isTrue);
    expect(theme.textTheme.bodyLarge?.height, 1.8);
    expect(theme.textTheme.bodyLarge?.fontFamily, AppTheme.fontFamily);
  });
}
