import 'package:bustan_al_rohban/app/app.dart';
import 'package:bustan_al_rohban/app/theme/app_theme.dart';
import 'package:bustan_al_rohban/core/content/content_loader.dart';
import 'package:bustan_al_rohban/features/library/data/library_repository.dart';
import 'package:bustan_al_rohban/features/reader/presentation/reader_screen.dart';
import 'package:bustan_al_rohban/features/reader/progress/reading_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../core/content/test_support.dart';
import '../../bookmarks/user_data_test_support.dart';
import '../../library/library_test_support.dart';
import '../../search/search_test_support.dart';
import 'progress_store_contract.dart';

TestBook _longBook(int count) => buildBook([
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
                  text: 'فقرة رقم $i من النص التجريبي الطويل.',
                ),
            ],
          ),
        ],
      ),
    ]);

Future<void> _pumpReader(
  WidgetTester tester,
  InMemoryProgressStore store, {
  String? paragraphId,
  int count = 400,
}) async {
  tester.view.physicalSize = const Size(400, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = LibraryRepository(ContentLoader(probeFor(_longBook(count))));
  await tester.pumpWidget(withUserData(
    RepositoryProvider<LibraryRepository>.value(
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
        ),
      ),
    ),
    progress: store,
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('Reading progress while reading', () {
    testWidgets('opening a section saves the first paragraph', (tester) async {
      final store = InMemoryProgressStore();
      await _pumpReader(tester, store);
      await tester.pump(const Duration(seconds: 1));
      final p = await store.forSection('sec-a-001');
      expect(p, isNotNull);
      expect(p!.paragraphId, 'p-000001');
      expect(p.saintId, 'saint-a');
      expect(p.contentVersion, 1);
    });

    testWidgets('scrolling saves a later paragraph', (tester) async {
      final store = InMemoryProgressStore();
      await _pumpReader(tester, store);
      await tester.drag(
          find.byKey(const Key('reader-list')), const Offset(0, -1500));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      final id = (await store.forSection('sec-a-001'))!.paragraphId;
      expect(id, isNot('p-000001'));
    });

    testWidgets('leaving the reader saves the position without waiting',
        (tester) async {
      final store = InMemoryProgressStore();
      await _pumpReader(tester, store, paragraphId: 'p-000300');
      // Leave before the debounce could fire.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      final p = await store.forSection('sec-a-001');
      expect(p!.paragraphId, 'p-000300');
    });

    testWidgets('reopening restores the saved position', (tester) async {
      final store = InMemoryProgressStore();
      await store.save(progress('sec-a-001', 'p-000300'));
      await _pumpReader(tester, store);
      expect(find.byKey(const Key('para-p-000300')), findsOneWidget);
      expect(find.byKey(const Key('para-p-000001')), findsNothing);
    });

    testWidgets('an explicit anchor wins over the saved position',
        (tester) async {
      final store = InMemoryProgressStore();
      await store.save(progress('sec-a-001', 'p-000300'));
      await _pumpReader(tester, store, paragraphId: 'p-000200');
      expect(find.byKey(const Key('para-p-000200')), findsOneWidget);
      expect(find.byKey(const Key('para-p-000300')), findsNothing);
    });

    testWidgets('progress saved for a paragraph not in the section is ignored',
        (tester) async {
      final store = InMemoryProgressStore();
      await store.save(progress('sec-a-001', 'p-999999'));
      await _pumpReader(tester, store);
      expect(find.byKey(const Key('para-p-000001')), findsOneWidget);
    });
  });

  group('Continue reading', () {
    Future<void> openLibrary(
      WidgetTester tester,
      InMemoryProgressStore store,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BustanApp(
        libraryRepository: repoFor(probeFor(searchBook())),
        progressStore: store,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-library')));
      await tester.pumpAndSettle();
    }

    testWidgets('no progress means no resume card', (tester) async {
      await openLibrary(tester, InMemoryProgressStore());
      expect(find.byKey(const Key('resume-card')), findsNothing);
    });

    testWidgets('shows where you stopped and opens it', (tester) async {
      final store = InMemoryProgressStore();
      await store.save(progress('sec-a-002', 'p-000004'));
      await openLibrary(tester, store);
      expect(find.byKey(const Key('resume-card')), findsOneWidget);
      expect(find.textContaining('القديس الأول › القسم الثاني'),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('resume-card')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reader-screen')), findsOneWidget);
      expect(find.byKey(const Key('para-p-000004')), findsOneWidget);
    });

    testWidgets('stale section and saint hints still resume correctly',
        (tester) async {
      final store = InMemoryProgressStore();
      await store.save(progress('sec-old', 'p-000005', saintId: 'saint-old'));
      await openLibrary(tester, store);
      expect(find.byKey(const Key('resume-card')), findsOneWidget);
      await tester.tap(find.byKey(const Key('resume-card')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('para-p-000005')), findsOneWidget);
    });

    testWidgets('a paragraph that no longer exists hides the card',
        (tester) async {
      final store = InMemoryProgressStore();
      await store.save(progress('sec-a-001', 'p-999999'));
      await openLibrary(tester, store);
      expect(find.byKey(const Key('resume-card')), findsNothing);
    });

    testWidgets('reading a section makes the card appear after going back',
        (tester) async {
      final store = InMemoryProgressStore();
      await openLibrary(tester, store);
      expect(find.byKey(const Key('resume-card')), findsNothing);

      final ctx = tester.element(find.byKey(const Key('library-screen')));
      GoRouter.of(ctx).push(
          '/library/book/saints/saint-a/sections/sec-a-002');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('library-screen')), findsOneWidget);
      expect(find.byKey(const Key('resume-card')), findsOneWidget);
    });
  });
}
