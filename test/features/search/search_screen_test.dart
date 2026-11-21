import 'package:bustan_al_rohban/app/app.dart';
import 'package:bustan_al_rohban/app/strings.dart';
import 'package:bustan_al_rohban/core/content/content_loader.dart';
import 'package:bustan_al_rohban/features/library/data/library_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/content/test_support.dart';
import '../library/library_test_support.dart';
import 'search_test_support.dart';

Future<void> _openSearch(WidgetTester tester, ProbeSource source) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BustanApp(libraryRepository: repoFor(source)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-search')));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('search-field')), text);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

Set<String> _resultIds(WidgetTester tester) {
  return {
    for (final e in find
        .byWidgetPredicate((w) =>
            w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('result-p-'))
        .evaluate())
      (e.widget.key as ValueKey<String>).value.substring('result-'.length),
  };
}

void main() {
  group('Search screen', () {
    testWidgets('shows the idle hint first', (tester) async {
      await _openSearch(tester, probeFor(searchBook()));
      expect(find.byKey(const Key('search-screen')), findsOneWidget);
      expect(find.byKey(const Key('search-idle')), findsOneWidget);
      expect(find.text(AppStrings.searchIdle), findsOneWidget);
    });

    testWidgets('screen is right-to-left', (tester) async {
      await _openSearch(tester, probeFor(searchBook()));
      final ctx = tester.element(find.byKey(const Key('search-screen')));
      expect(Directionality.of(ctx), TextDirection.rtl);
    });

    testWidgets('typing a keyword lists matching paragraphs', (tester) async {
      await _openSearch(tester, probeFor(searchBook()));
      await _type(tester, 'رحمة');
      expect(find.byKey(const Key('search-count')), findsOneWidget);
      expect(find.text('2 ${AppStrings.searchResultsWord}'), findsOneWidget);
      expect(_resultIds(tester), {'p-000001', 'p-000003'});
    });

    testWidgets('the same words without diacritics give the same results',
        (tester) async {
      await _openSearch(tester, probeFor(searchBook()));
      await _type(tester, 'رَحْمَة');
      final withDiacritics = _resultIds(tester);
      await _type(tester, 'رحمه');
      expect(_resultIds(tester), withDiacritics);
      expect(withDiacritics, isNotEmpty);
    });

    testWidgets('equivalent alef spellings find the same results',
        (tester) async {
      await _openSearch(tester, probeFor(searchBook()));
      for (final q in ['ابونا', 'أبونا', 'إبونا']) {
        await _type(tester, q);
        expect(_resultIds(tester), {'p-000002', 'p-000006'}, reason: q);
      }
    });

    testWidgets('the snippet shows the original vowelled text',
        (tester) async {
      await _openSearch(tester, probeFor(searchBook()));
      await _type(tester, 'رحمة');
      final snippet = tester.widget<Text>(find.descendant(
        of: find.byKey(const Key('result-p-000001')),
        matching: find.byKey(const Key('result-snippet')),
      ));
      expect(snippet.textSpan!.toPlainText(), vowelledText);
    });

    testWidgets('matches are highlighted in bold', (tester) async {
      await _openSearch(tester, probeFor(searchBook()));
      await _type(tester, 'الرب');
      final snippet = tester.widget<Text>(find.descendant(
        of: find.byKey(const Key('result-p-000004')),
        matching: find.byKey(const Key('result-snippet')),
      ));
      final bold = <String>[];
      snippet.textSpan!.visitChildren((span) {
        if (span is TextSpan && span.style?.fontWeight == FontWeight.bold) {
          bold.add(span.text!);
        }
        return true;
      });
      expect(bold, ['الرب']);
    });

    testWidgets('no match shows the empty message', (tester) async {
      await _openSearch(tester, probeFor(searchBook()));
      await _type(tester, 'غير موجود');
      expect(find.byKey(const Key('empty-view')), findsOneWidget);
      expect(find.text(AppStrings.searchNoResults), findsOneWidget);
    });

    testWidgets('clear returns to the idle hint', (tester) async {
      await _openSearch(tester, probeFor(searchBook()));
      await _type(tester, 'رحمة');
      await tester.tap(find.byKey(const Key('search-clear')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('search-idle')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('search-field')))
            .controller!
            .text,
        isEmpty,
      );
    });

    testWidgets('a result opens the reader at its source paragraph',
        (tester) async {
      await _openSearch(tester, probeFor(searchBook()));
      await _type(tester, 'قال الرب');
      await tester.tap(find.byKey(const Key('result-p-000004')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reader-screen')), findsOneWidget);
      expect(find.byKey(const Key('para-p-000004')), findsOneWidget);
      expect(find.text('القسم الثاني'), findsWidgets);
      expect(find.text('قال الرب لموسى كلمة'), findsOneWidget);
    });

    testWidgets('a result in the other saint opens that saint',
        (tester) async {
      await _openSearch(tester, probeFor(searchBook()));
      await _type(tester, 'انقطاع');
      await tester.tap(find.byKey(const Key('result-p-000006')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('para-p-000006')), findsOneWidget);
    });

    testWidgets('a content error shows the error view; retry recovers',
        (tester) async {
      final source = probeFor(searchBook());
      final mem = source.inner as InMemoryContentSource;
      final good = mem.files['saints/saint-b.json']!;
      mem.files['saints/saint-b.json'] = '{ broken';
      await _openSearch(tester, source);
      await _type(tester, 'رحمة');
      expect(find.byKey(const Key('error-view')), findsOneWidget);

      mem.files['saints/saint-b.json'] = good;
      await tester.tap(find.byKey(const Key('retry-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('error-view')), findsNothing);
      expect(find.byKey(const Key('search-count')), findsOneWidget);
    });
  });

  group('Search on the shipped FAKE content', () {
    testWidgets('equivalent spellings match the vowelled fake paragraph',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BustanApp(
          libraryRepository: LibraryRepository(
          ContentLoader(SyncDiskContentSource('test/fixtures/fake_content'))),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-search')));
      await tester.pumpAndSettle();

      // p-000002 is written with full diacritics in the fixture.
      await _type(tester, 'تجريبية');
      expect(_resultIds(tester), contains('p-000002'));
      expect(_resultIds(tester).length, greaterThan(5));

      await _type(tester, 'ثانية');
      expect(_resultIds(tester), containsAll(['p-000002', 'p-000012']));
    });
  });
}
