import 'package:bustan_al_rohban/core/content/preview/content_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

void main() {
  final good = buildBook([
    saintJson(id: 'saint-a', title: '[تجريبي] قديس أ', sections: [
      sectionJson(
          id: 'sec-a-001',
          title: '[تجريبي] قسم 1',
          paragraphs: [paraJson(id: 'p-000001', page: 4)]),
      sectionJson(
          id: 'sec-a-002',
          order: 2,
          title: '[تجريبي] قسم 2',
          paragraphs: [paraJson(id: 'p-000002', page: null)]),
    ]),
    saintJson(id: 'saint-b', order: 2, title: '[تجريبي] قديس ب', sections: [
      sectionJson(
          id: 'sec-b-001', paragraphs: [paraJson(id: 'p-000003', page: 1)]),
    ]),
  ], fixture: true);

  final bad = buildBook([saintJson()], hashOverride: 'sha256:abc');

  Widget app() => MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ContentPreviewScreen(
          validSource: InMemoryContentSource(
              {'manifest.json': good.manifestJson, ...good.files}),
          invalidSource: InMemoryContentSource(
              {'manifest.json': bad.manifestJson, ...bad.files}),
        ),
      );

  testWidgets('shows the FAKE banner and all saints', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fake-banner')), findsOneWidget);
    expect(find.byKey(const Key('saint-saint-a')), findsOneWidget);
    expect(find.byKey(const Key('saint-saint-b')), findsOneWidget);
    expect(find.text('[تجريبي] قديس أ'), findsOneWidget);
  });

  testWidgets('expanding a saint shows its sections in order', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('saint-saint-a')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('section-sec-a-001')), findsOneWidget);
    expect(find.byKey(const Key('section-sec-a-002')), findsOneWidget);
    final first = tester.getTopLeft(find.byKey(const Key('section-sec-a-001')));
    final second =
        tester.getTopLeft(find.byKey(const Key('section-sec-a-002')));
    expect(first.dy, lessThan(second.dy));
  });

  testWidgets('loading the invalid fixture shows its errors', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('load-invalid')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('content-error')), findsOneWidget);
    expect(find.byKey(const Key('issue-0')), findsOneWidget);
    expect(find.textContaining('content-hash-mismatch'), findsOneWidget);
  });

  testWidgets('can return to the valid content after an error',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('load-invalid')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('load-valid')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('content-error')), findsNothing);
    expect(find.byKey(const Key('saint-saint-a')), findsOneWidget);
  });
}
