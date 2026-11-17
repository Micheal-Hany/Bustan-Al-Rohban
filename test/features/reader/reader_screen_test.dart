import 'package:bustan_al_rohban/app/app.dart';
import 'package:bustan_al_rohban/app/strings.dart';
import 'package:bustan_al_rohban/app/router/app_router.dart';
import 'package:bustan_al_rohban/app/theme/app_theme.dart';
import 'package:bustan_al_rohban/core/content/content_loader.dart';
import 'package:bustan_al_rohban/features/library/data/library_repository.dart';
import 'package:bustan_al_rohban/features/reader/domain/editorial.dart';
import 'package:bustan_al_rohban/features/reader/presentation/reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../core/content/test_support.dart';
import '../bookmarks/user_data_test_support.dart';
import '../library/library_test_support.dart';
import 'package:bustan_al_rohban/app/theme/app_icons.dart';

const _diacritics = 'السَّلَامُ  عَلَيْكُمْ\nوَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ ';

TestBook _readerBook({bool fixture = false}) => buildBook([
      saintJson(
        id: 'saint-a',
        title: 'القديس',
        sections: [
          sectionJson(
            id: 'sec-a-001',
            title: 'عنوان القسم',
            paragraphs: [
              paraJson(id: 'p-000001', order: 1, page: 3, text: _diacritics),
              paraJson(
                  id: 'p-000002',
                  order: 2,
                  page: 3,
                  kind: 'heading',
                  text: 'عنوان فرعي'),
              paraJson(id: 'p-000003', order: 3, page: 4, text: 'فقرة ثالثة'),
              paraJson(id: 'p-000004', order: 4, page: null, text: 'فقرة بلا صفحة'),
            ],
          ),
        ],
      ),
    ], fixture: fixture);

TestBook _longBook(int count, {String? longText}) => buildBook([
      saintJson(
        id: 'saint-a',
        sections: [
          sectionJson(
            id: 'sec-a-001',
            paragraphs: [
              for (var i = 1; i <= count; i++)
                paraJson(
                  id: 'p-${i.toString().padLeft(6, '0')}',
                  order: i,
                  page: 1 + i ~/ 10,
                  text: longText ?? 'فقرة رقم $i من النص التجريبي الطويل.',
                ),
            ],
          ),
        ],
      ),
    ]);

Future<void> _pumpReader(
  WidgetTester tester,
  TestBook book, {
  String? paragraphId,
  Size size = const Size(800, 1200),
  EditorialSource? editorial,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = LibraryRepository(
    ContentLoader(probeFor(book)),
  );
  await tester.pumpWidget(
    withUserData(RepositoryProvider<LibraryRepository>.value(
      value: repo,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ReaderScreen(
          saintId: 'saint-a',
          sectionId: 'sec-a-001',
          paragraphId: paragraphId,
          editorial: editorial,
        ),
      ),
    )),
  );
  await tester.pumpAndSettle();
}

double _fontSize(WidgetTester tester, String paragraphId) {
  final text =
      tester.widget<Text>(find.byKey(Key('para-text-$paragraphId')));
  return text.style!.fontSize!;
}

void main() {
  group('Reader rendering', () {
    testWidgets('shows header, paragraphs and page markers', (tester) async {
      await _pumpReader(tester, _readerBook());
      expect(find.byKey(const Key('reader-screen')), findsOneWidget);
      expect(find.byKey(const Key('reader-section-title')), findsOneWidget);
      for (final id in ['p-000001', 'p-000002', 'p-000003', 'p-000004']) {
        expect(find.byKey(Key('para-$id')), findsOneWidget, reason: id);
      }
      expect(find.text('${AppStrings.pageWord} 3'), findsWidgets);
      expect(find.text('${AppStrings.pageWord} 4'), findsOneWidget);
      expect(find.text(AppStrings.pagesUnknown), findsWidgets);
    });

    testWidgets('original text is rendered exactly as stored',
        (tester) async {
      await _pumpReader(tester, _readerBook());
      // Exact match, including diacritics, double space, newline, trailing space.
      expect(find.text(_diacritics), findsOneWidget);
      expect(find.text('فقرة ثالثة'), findsOneWidget);
    });

    testWidgets('headings are bold and larger than body text',
        (tester) async {
      await _pumpReader(tester, _readerBook());
      final heading =
          tester.widget<Text>(find.byKey(const Key('para-text-p-000002')));
      expect(heading.style!.fontWeight, FontWeight.bold);
      expect(_fontSize(tester, 'p-000002'),
          greaterThan(_fontSize(tester, 'p-000001')));
    });

    testWidgets('layout is right-to-left', (tester) async {
      await _pumpReader(tester, _readerBook());
      final ctx = tester.element(find.byKey(const Key('reader-screen')));
      expect(Directionality.of(ctx), TextDirection.rtl);
    });

    testWidgets('a missing section shows the not-found message',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = LibraryRepository(ContentLoader(probeFor(_readerBook())));
      await tester.pumpWidget(withUserData(RepositoryProvider<LibraryRepository>.value(
        value: repo,
        child: const MaterialApp(
          home: ReaderScreen(saintId: 'saint-a', sectionId: 'sec-zzz'),
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('empty-view')), findsOneWidget);
      expect(find.text(AppStrings.notFound), findsOneWidget);
    });
  });

  group('Text size', () {
    testWidgets('larger and smaller change the paragraph font size',
        (tester) async {
      await _pumpReader(tester, _readerBook());
      final base = _fontSize(tester, 'p-000003');
      expect(find.text('100%'), findsOneWidget);

      await tester.tap(find.byKey(const Key('text-larger')));
      await tester.pumpAndSettle();
      expect(_fontSize(tester, 'p-000003'), greaterThan(base));
      expect(find.text('115%'), findsOneWidget);

      await tester.tap(find.byKey(const Key('text-smaller')));
      await tester.tap(find.byKey(const Key('text-smaller')));
      await tester.pumpAndSettle();
      expect(_fontSize(tester, 'p-000003'), lessThan(base));
      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('buttons disable at the limits', (tester) async {
      await _pumpReader(tester, _readerBook());
      for (var i = 0; i < 10; i++) {
        final b = tester
            .widget<IconButton>(find.byKey(const Key('text-larger')));
        if (b.onPressed == null) break;
        await tester.tap(find.byKey(const Key('text-larger')));
        await tester.pumpAndSettle();
      }
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('text-larger')))
            .onPressed,
        isNull,
      );
      expect(find.text('200%'), findsOneWidget);
    });

    testWidgets('maximum size on a narrow screen does not overflow',
        (tester) async {
      await _pumpReader(
        tester,
        _readerBook(),
        size: const Size(320, 640),
      );
      for (var i = 0; i < 8; i++) {
        final b = tester
            .widget<IconButton>(find.byKey(const Key('text-larger')));
        if (b.onPressed == null) break;
        await tester.tap(find.byKey(const Key('text-larger')));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('Long text', () {
    testWidgets('a very long single paragraph renders without errors',
        (tester) async {
      final longText = List.generate(
        3000,
        (i) => 'هذه جملة طويلة رقم $i تتكرر لاختبار التفاف النص.',
      ).join(' ');
      await _pumpReader(
        tester,
        _longBook(1, longText: longText),
        size: const Size(360, 640),
      );
      expect(find.byKey(const Key('para-p-000001')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('many paragraphs are built lazily', (tester) async {
      await _pumpReader(tester, _longBook(400), size: const Size(400, 600));
      expect(find.byKey(const Key('para-p-000001')), findsOneWidget);
      expect(find.byKey(const Key('para-p-000400')), findsNothing);
      expect(
        find.byType(Text).evaluate().length,
        lessThan(100),
        reason: 'only visible rows are built',
      );
    });

    testWidgets('dragging scrolls the content', (tester) async {
      await _pumpReader(tester, _longBook(400), size: const Size(400, 600));
      final before =
          tester.getTopLeft(find.byKey(const Key('para-p-000002'))).dy;
      await tester.drag(
          find.byKey(const Key('reader-list')), const Offset(0, -200));
      await tester.pumpAndSettle();
      final after =
          tester.getTopLeft(find.byKey(const Key('para-p-000002'))).dy;
      expect(after, lessThan(before));
    });

    testWidgets('opens at a paragraph anchor far down the section',
        (tester) async {
      await _pumpReader(
        tester,
        _longBook(400),
        size: const Size(400, 600),
        paragraphId: 'p-000300',
      );
      expect(find.byKey(const Key('para-p-000300')), findsOneWidget);
      expect(find.byKey(const Key('para-p-000001')), findsNothing);
    });
  });

  group('Editorial additions', () {
    testWidgets('are visibly separate from the original text',
        (tester) async {
      await _pumpReader(
        tester,
        _readerBook(),
        editorial: const FakeEditorialSource(),
      );
      final card = find.byKey(const Key('editorial-fake-ins-sec-a-001'));
      expect(card, findsOneWidget);
      expect(find.text(AppStrings.editorialLabel), findsOneWidget);
      expect(find.byIcon(AppIcons.editorial), findsOneWidget);
      // Not an original paragraph: no paragraph key, different container.
      expect(
        find.descendant(of: card, matching: find.byType(Container)),
        findsWidgets,
      );
      expect(find.byKey(const Key('para-fake-ins-sec-a-001')), findsNothing);
    });

    testWidgets('fixture books show the FAKE editorial sample',
        (tester) async {
      await _pumpReader(tester, _readerBook(fixture: true));
      expect(find.text(AppStrings.editorialLabel), findsOneWidget);
    });

    testWidgets('real books show none', (tester) async {
      await _pumpReader(tester, _readerBook());
      expect(find.text(AppStrings.editorialLabel), findsNothing);
    });
  });

  group('Routing', () {
    testWidgets('a deep link with ?p= opens at that paragraph',
        (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final source = probeFor(_longBook(400));
      await tester.pumpWidget(BustanApp(libraryRepository: repoFor(source)));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byKey(const Key('home-screen')));
      GoRouter.of(ctx).push(AppRoutes.section(
        'saint-a',
        'sec-a-001',
        paragraphId: 'p-000250',
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reader-screen')), findsOneWidget);
      expect(find.byKey(const Key('para-p-000250')), findsOneWidget);
    });

    test('AppRoutes.section builds the path with and without an anchor', () {
      expect(AppRoutes.section('s', 'c'), '/library/book/saints/s/sections/c');
      expect(AppRoutes.section('s', 'c', paragraphId: 'p-000001'),
          '/library/book/saints/s/sections/c?p=p-000001');
    });
  });
}
