import 'package:bustan_al_rohban/app/app.dart';
import 'package:bustan_al_rohban/app/strings.dart';
import 'package:bustan_al_rohban/features/bookmarks/domain/bookmark_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../library/library_test_support.dart';
import '../search/search_test_support.dart';
import 'user_data_test_support.dart';
import 'package:bustan_al_rohban/app/theme/app_icons.dart';

const _sectionPath = '/library/book/saints/saint-a/sections/sec-a-001';

Future<void> _pumpApp(
  WidgetTester tester,
  BookmarkStore store, {
  ProbeSource? source,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BustanApp(
    libraryRepository: repoFor(source ?? probeFor(searchBook())),
    bookmarkStore: store,
  ));
  await tester.pumpAndSettle();
}

Future<void> _openReader(WidgetTester tester) async {
  final ctx = tester.element(find.byKey(const Key('home-screen')));
  GoRouter.of(ctx).push(_sectionPath);
  await tester.pumpAndSettle();
}

Future<void> _openBookmarks(WidgetTester tester) async {
  final ctx = tester.element(find.byKey(const Key('home-screen')));
  GoRouter.of(ctx).push('/bookmarks');
  await tester.pumpAndSettle();
}

IconData _iconOf(WidgetTester tester, String paragraphId) {
  final button =
      tester.widget<IconButton>(find.byKey(Key('bookmark-$paragraphId')));
  return (button.icon as Icon).icon!;
}

void main() {
  group('Bookmarking in the reader', () {
    testWidgets('tapping the icon adds, tapping again removes',
        (tester) async {
      final store = InMemoryBookmarkStore();
      await _pumpApp(tester, store);
      await _openReader(tester);

      expect(_iconOf(tester, 'p-000002'), AppIcons.bookmarkOff);
      await tester.tap(find.byKey(const Key('bookmark-p-000002')));
      await tester.pumpAndSettle();
      expect(_iconOf(tester, 'p-000002'), AppIcons.bookmarkOn);

      final saved = await store.all();
      expect(saved, hasLength(1));
      expect(saved.single.paragraphId, 'p-000002');
      expect(saved.single.saintId, 'saint-a');
      expect(saved.single.sectionId, 'sec-a-001');
      expect(saved.single.offset, 0);
      expect(saved.single.contentVersion, 1);

      await tester.tap(find.byKey(const Key('bookmark-p-000002')));
      await tester.pumpAndSettle();
      expect(_iconOf(tester, 'p-000002'), AppIcons.bookmarkOff);
      expect(await store.all(), isEmpty);
    });

    testWidgets('an existing bookmark is shown as filled on open',
        (tester) async {
      final store = InMemoryBookmarkStore();
      await store.add(
        saintId: 'saint-a',
        sectionId: 'sec-a-001',
        paragraphId: 'p-000001',
        contentVersion: 1,
      );
      await _pumpApp(tester, store);
      await _openReader(tester);
      expect(_iconOf(tester, 'p-000001'), AppIcons.bookmarkOn);
      expect(_iconOf(tester, 'p-000002'), AppIcons.bookmarkOff);
    });

    testWidgets('a failed save shows a message and keeps the old state',
        (tester) async {
      final store = FailingBookmarkStore(InMemoryBookmarkStore())
        ..failWrites = true;
      await _pumpApp(tester, store);
      await _openReader(tester);
      await tester.tap(find.byKey(const Key('bookmark-p-000001')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.bookmarkSaveFailed), findsOneWidget);
      expect(_iconOf(tester, 'p-000001'), AppIcons.bookmarkOff);
    });

    testWidgets('bookmark buttons have accessible labels', (tester) async {
      await _pumpApp(tester, InMemoryBookmarkStore());
      await _openReader(tester);
      final button =
          tester.widget<IconButton>(find.byKey(const Key('bookmark-p-000001')));
      expect(button.tooltip, AppStrings.addBookmark);
    });
  });

  group('Bookmarks screen', () {
    testWidgets('empty state', (tester) async {
      await _pumpApp(tester, InMemoryBookmarkStore());
      await _openBookmarks(tester);
      expect(find.byKey(const Key('bookmarks-screen')), findsOneWidget);
      expect(find.text(AppStrings.bookmarksEmpty), findsOneWidget);
    });

    testWidgets('home entry opens the real bookmarks screen', (tester) async {
      await _pumpApp(tester, InMemoryBookmarkStore());
      await tester.tap(find.byKey(const Key('nav-bookmarks')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bookmarks-screen')), findsOneWidget);
      expect(find.text(AppStrings.underConstruction), findsNothing);
    });

    testWidgets('lists a bookmark with its location and original text',
        (tester) async {
      final store = InMemoryBookmarkStore();
      await store.add(
        saintId: 'saint-a',
        sectionId: 'sec-a-001',
        paragraphId: 'p-000001',
        contentVersion: 1,
      );
      await _pumpApp(tester, store);
      await _openBookmarks(tester);
      expect(find.textContaining('القديس الأول › القسم الأول'),
          findsOneWidget);
      expect(find.text('${AppStrings.pageWord} 1'), findsOneWidget);
      expect(find.text(vowelledText), findsOneWidget);
    });

    testWidgets('tapping a bookmark opens the reader at the paragraph',
        (tester) async {
      final store = InMemoryBookmarkStore();
      final b = await store.add(
        saintId: 'saint-a',
        sectionId: 'sec-a-002',
        paragraphId: 'p-000004',
        contentVersion: 1,
      );
      await _pumpApp(tester, store);
      await _openBookmarks(tester);
      await tester.tap(find.byKey(Key('bookmark-tile-${b.id}')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reader-screen')), findsOneWidget);
      expect(find.byKey(const Key('para-p-000004')), findsOneWidget);
    });

    testWidgets('delete removes the bookmark and it stays removed',
        (tester) async {
      final store = InMemoryBookmarkStore();
      final b = await store.add(
        saintId: 'saint-a',
        sectionId: 'sec-a-001',
        paragraphId: 'p-000001',
        contentVersion: 1,
      );
      await _pumpApp(tester, store);
      await _openBookmarks(tester);
      await tester.tap(find.byKey(Key('bookmark-delete-${b.id}')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.bookmarksEmpty), findsOneWidget);
      expect(await store.all(), isEmpty);
    });

    testWidgets('a bookmark whose paragraph is gone can be deleted',
        (tester) async {
      final store = InMemoryBookmarkStore();
      final b = await store.add(
        saintId: 'saint-a',
        sectionId: 'sec-a-001',
        paragraphId: 'p-999999',
        contentVersion: 1,
      );
      await _pumpApp(tester, store);
      await _openBookmarks(tester);
      expect(find.text(AppStrings.bookmarkUnavailable), findsOneWidget);
      await tester.tap(find.byKey(Key('bookmark-delete-${b.id}')));
      await tester.pumpAndSettle();
      expect(await store.all(), isEmpty);
    });

    testWidgets('newest bookmark is listed first', (tester) async {
      var t = DateTime.utc(2026, 1, 1);
      final store = InMemoryBookmarkStore(clock: () {
        t = t.add(const Duration(seconds: 1));
        return t;
      });
      final a = await store.add(
          saintId: 'saint-a',
          sectionId: 'sec-a-001',
          paragraphId: 'p-000001',
          contentVersion: 1);
      final b = await store.add(
          saintId: 'saint-a',
          sectionId: 'sec-a-002',
          paragraphId: 'p-000004',
          contentVersion: 1);
      await _pumpApp(tester, store);
      await _openBookmarks(tester);
      final first =
          tester.getTopLeft(find.byKey(Key('bookmark-tile-${b.id}'))).dy;
      final second =
          tester.getTopLeft(find.byKey(Key('bookmark-tile-${a.id}'))).dy;
      expect(first, lessThan(second));
    });

    testWidgets('screen is right-to-left', (tester) async {
      await _pumpApp(tester, InMemoryBookmarkStore());
      await _openBookmarks(tester);
      final ctx = tester.element(find.byKey(const Key('bookmarks-screen')));
      expect(Directionality.of(ctx), TextDirection.rtl);
    });
  });

  group('Restart', () {
    testWidgets('a bookmark and its removal survive an app restart',
        (tester) async {
      // The same store instance stands for the database that outlives the app.
      final store = InMemoryBookmarkStore();

      await _pumpApp(tester, store);
      await _openReader(tester);
      await tester.tap(find.byKey(const Key('bookmark-p-000003')));
      await tester.pumpAndSettle();

      // "Restart": throw the whole app away and start a new one.
      await tester.pumpWidget(const SizedBox());
      await _pumpApp(tester, store);
      await _openBookmarks(tester);
      expect(find.text('رحمة الله'), findsOneWidget);

      final id = (await store.all()).single.id;
      await tester.tap(find.byKey(Key('bookmark-delete-$id')));
      await tester.pumpAndSettle();

      // Restart again: still removed.
      await tester.pumpWidget(const SizedBox());
      await _pumpApp(tester, store);
      await _openBookmarks(tester);
      expect(find.text(AppStrings.bookmarksEmpty), findsOneWidget);
    });
  });
}
