import 'package:bustan_al_rohban/app/app.dart';
import 'package:bustan_al_rohban/app/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/content/test_support.dart';
import 'library_test_support.dart';

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

Future<void> _openLibrary(WidgetTester tester, ProbeSource source) async {
  await tester.pumpWidget(BustanApp(libraryRepository: repoFor(source)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-library')));
  await tester.pumpAndSettle();
}

void main() {
  group('Library navigation', () {
    testWidgets('home -> library -> book -> saints -> sections -> section',
        (tester) async {
      final source = probeFor(twoSaintBook());
      await _openLibrary(tester, source);

      expect(find.byKey(const Key('library-screen')), findsOneWidget);
      expect(find.byKey(const Key('book-tile')), findsOneWidget);
      expect(find.text('كتاب'), findsWidgets);

      await tester.tap(find.byKey(const Key('book-tile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('book-overview-screen')), findsOneWidget);
      expect(find.byKey(const Key('book-title')), findsOneWidget);

      await tester.tap(find.byKey(const Key('saints-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('saints-list-screen')), findsOneWidget);
      expect(find.byKey(const Key('saint-tile-saint-a')), findsOneWidget);
      expect(find.byKey(const Key('saint-tile-saint-b')), findsOneWidget);
      // No saint file read until a saint is opened.
      expect(
          source.reads.keys.where((k) => k.startsWith('saints/')), isEmpty);

      await tester.tap(find.byKey(const Key('saint-tile-saint-a')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sections-screen')), findsOneWidget);
      expect(find.byKey(const Key('section-tile-sec-a-001')), findsOneWidget);
      expect(find.byKey(const Key('section-tile-sec-a-002')), findsOneWidget);
      expect(find.textContaining('3-5'), findsOneWidget);
      expect(find.textContaining(AppStrings.pagesUnknown), findsOneWidget);
      expect(source.reads['saints/saint-a.json'], isNotNull);
      expect(source.reads.containsKey('saints/saint-b.json'), isFalse);

      await tester.tap(find.byKey(const Key('section-tile-sec-a-001')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('section-screen')), findsOneWidget);
      expect(find.textContaining(AppStrings.readerComingSoon), findsOneWidget);

      // Back out, one screen at a time.
      for (final key in [
        'sections-screen',
        'saints-list-screen',
        'book-overview-screen',
        'library-screen',
        'home-screen',
      ]) {
        await _back(tester);
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
    });

    testWidgets('saints are listed in book order', (tester) async {
      await _openLibrary(tester, probeFor(twoSaintBook()));
      await tester.tap(find.byKey(const Key('book-tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('saints-button')));
      await tester.pumpAndSettle();
      final a = tester.getTopLeft(find.byKey(const Key('saint-tile-saint-a')));
      final b = tester.getTopLeft(find.byKey(const Key('saint-tile-saint-b')));
      expect(a.dy, lessThan(b.dy));
    });

    testWidgets('fixture book shows the FAKE banner', (tester) async {
      final book = buildBook([saintJson()], fixture: true);
      await _openLibrary(tester, probeFor(book));
      await tester.tap(find.byKey(const Key('book-tile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fake-banner')), findsOneWidget);
    });

    testWidgets('non-fixture book has no FAKE banner', (tester) async {
      await _openLibrary(tester, probeFor(twoSaintBook()));
      await tester.tap(find.byKey(const Key('book-tile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fake-banner')), findsNothing);
    });

    testWidgets('library screens are RTL', (tester) async {
      await _openLibrary(tester, probeFor(twoSaintBook()));
      final ctx = tester.element(find.byKey(const Key('library-screen')));
      expect(Directionality.of(ctx), TextDirection.rtl);
    });
  });

  group('Library states', () {
    testWidgets('shows loading, then content', (tester) async {
      final source = probeFor(twoSaintBook())..hold();
      await tester.pumpWidget(BustanApp(libraryRepository: repoFor(source)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-library')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('loading-view')), findsOneWidget);

      source.release();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('loading-view')), findsNothing);
      expect(find.byKey(const Key('book-tile')), findsOneWidget);
    });

    testWidgets('error view with retry recovers', (tester) async {
      final book = twoSaintBook();
      final source = probeFor(book);
      final mem = source.inner as InMemoryContentSource;
      mem.files.remove('manifest.json');
      await _openLibrary(tester, source);
      expect(find.byKey(const Key('error-view')), findsOneWidget);
      expect(find.textContaining('missing-file'), findsOneWidget);

      mem.files['manifest.json'] = book.manifestJson;
      await tester.tap(find.byKey(const Key('retry-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('error-view')), findsNothing);
      expect(find.byKey(const Key('book-tile')), findsOneWidget);
    });

    testWidgets('empty library shows the empty message', (tester) async {
      await _openLibrary(tester, probeFor(buildBook([])));
      expect(find.byKey(const Key('empty-view')), findsOneWidget);
      expect(find.text(AppStrings.emptyLibrary), findsOneWidget);
    });

    testWidgets('saint without sections shows the empty message',
        (tester) async {
      final book = buildBook([saintJson(sections: [])]);
      await _openLibrary(tester, probeFor(book));
      await tester.tap(find.byKey(const Key('book-tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('saints-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('saint-tile-saint-a')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('empty-view')), findsOneWidget);
      expect(find.text(AppStrings.emptySections), findsOneWidget);
    });

    testWidgets('corrupt saint file shows error with retry', (tester) async {
      final book = twoSaintBook();
      final source = probeFor(book);
      final mem = source.inner as InMemoryContentSource;
      final good = mem.files['saints/saint-a.json']!;
      mem.files['saints/saint-a.json'] = '{ broken';
      await _openLibrary(tester, source);
      await tester.tap(find.byKey(const Key('book-tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('saints-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('saint-tile-saint-a')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('error-view')), findsOneWidget);

      mem.files['saints/saint-a.json'] = good;
      await tester.tap(find.byKey(const Key('retry-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('section-tile-sec-a-001')), findsOneWidget);
    });
  });

  group('Shipped FAKE content', () {
    testWidgets('default app reads the bundled assets', (tester) async {
      await tester.pumpWidget(const BustanApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-library')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('book-tile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fake-banner')), findsOneWidget);
      await tester.tap(find.byKey(const Key('saints-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('saint-tile-saint-fake-one')),
          findsOneWidget);
    });
  });
}
