import 'package:bustan_al_rohban/app/strings.dart';
import 'package:bustan_al_rohban/features/bookmarks/domain/bookmark_store.dart';
import 'package:bustan_al_rohban/features/bookmarks/presentation/bookmark_list_cubit.dart';
import 'package:bustan_al_rohban/features/bookmarks/presentation/bookmarks_cubit.dart';
import 'package:bustan_al_rohban/features/library/presentation/load_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../library/library_test_support.dart';
import '../search/search_test_support.dart';
import 'user_data_test_support.dart';

Future<void> _toggle(BookmarksCubit c, String paragraphId) => c.toggle(
      saintId: 'saint-a',
      sectionId: 'sec-a-001',
      paragraphId: paragraphId,
      contentVersion: 1,
    );

void main() {
  group('BookmarksCubit', () {
    test('starts loading, then loaded and empty', () async {
      final c = BookmarksCubit(InMemoryBookmarkStore());
      expect(c.state.status, BookmarksStatus.loading);
      await c.load();
      expect(c.state.status, BookmarksStatus.loaded);
      expect(c.state.items, isEmpty);
      await c.close();
    });

    test('toggle adds, then removes', () async {
      final c = BookmarksCubit(InMemoryBookmarkStore())..load();
      await _toggle(c, 'p-000001');
      expect(c.state.isBookmarked('p-000001'), isTrue);
      expect(c.state.items, hasLength(1));
      await _toggle(c, 'p-000001');
      expect(c.state.isBookmarked('p-000001'), isFalse);
      expect(c.state.items, isEmpty);
      await c.close();
    });

    test('remove deletes by id', () async {
      final c = BookmarksCubit(InMemoryBookmarkStore())..load();
      await _toggle(c, 'p-000001');
      await _toggle(c, 'p-000002');
      await c.remove(c.state.forParagraph('p-000001')!.id);
      expect(c.state.items.map((b) => b.paragraphId), ['p-000002']);
      await c.close();
    });

    test('loads what a previous run saved (restart)', () async {
      final store = InMemoryBookmarkStore();
      final first = BookmarksCubit(store)..load();
      await _toggle(first, 'p-000001');
      await first.close();

      final second = BookmarksCubit(store);
      await second.load();
      expect(second.state.isBookmarked('p-000001'), isTrue);
      await second.close();
    });

    test('a failed write keeps the list and reports an error', () async {
      final store = FailingBookmarkStore(InMemoryBookmarkStore());
      final c = BookmarksCubit(store)..load();
      await _toggle(c, 'p-000001');
      store.failWrites = true;
      await _toggle(c, 'p-000002');
      expect(c.state.error, AppStrings.bookmarkSaveFailed);
      expect(c.state.items.map((b) => b.paragraphId), ['p-000001']);
      await c.close();
    });

    test('a failed read gives the error status', () async {
      final store = FailingBookmarkStore(InMemoryBookmarkStore())
        ..failReads = true;
      final c = BookmarksCubit(store);
      await c.load();
      expect(c.state.status, BookmarksStatus.error);
      store.failReads = false;
      await c.load();
      expect(c.state.status, BookmarksStatus.loaded);
      await c.close();
    });
  });

  group('BookmarkListCubit', () {
    test('resolves bookmarks to their current location', () async {
      final store = InMemoryBookmarkStore();
      final source = BookmarksCubit(store);
      await source.load();
      await source.toggle(
        saintId: 'saint-a',
        sectionId: 'sec-a-002',
        paragraphId: 'p-000004',
        contentVersion: 1,
      );
      final list = BookmarkListCubit(
          source, repoFor(probeFor(searchBook())));
      await pumpEventQueue();
      expect(list.state.status, LoadStatus.loaded);
      final v = list.state.views.single;
      expect(v.isAvailable, isTrue);
      expect(v.location!.saint.title, 'القديس الأول');
      expect(v.location!.section.title, 'القسم الثاني');
      expect(v.location!.paragraph.text, 'قال الرب لموسى كلمة');
      await list.close();
      await source.close();
    });

    test('is empty with no bookmarks', () async {
      final source = BookmarksCubit(InMemoryBookmarkStore());
      await source.load();
      final list =
          BookmarkListCubit(source, repoFor(probeFor(searchBook())));
      await pumpEventQueue();
      expect(list.state.status, LoadStatus.empty);
      await list.close();
      await source.close();
    });

    test('a bookmark whose paragraph is gone is marked unavailable',
        () async {
      final source = BookmarksCubit(InMemoryBookmarkStore());
      await source.load();
      await source.toggle(
        saintId: 'saint-a',
        sectionId: 'sec-a-001',
        paragraphId: 'p-999999',
        contentVersion: 1,
      );
      final list =
          BookmarkListCubit(source, repoFor(probeFor(searchBook())));
      await pumpEventQueue();
      expect(list.state.status, LoadStatus.loaded);
      expect(list.state.views.single.isAvailable, isFalse);
      await list.close();
      await source.close();
    });

    test('wrong saint and section hints still resolve by paragraph id',
        () async {
      final source = BookmarksCubit(InMemoryBookmarkStore());
      await source.load();
      await source.toggle(
        saintId: 'saint-gone',
        sectionId: 'sec-gone',
        paragraphId: 'p-000005',
        contentVersion: 1,
      );
      final list =
          BookmarkListCubit(source, repoFor(probeFor(searchBook())));
      await pumpEventQueue();
      final loc = list.state.views.single.location!;
      expect(loc.saint.id, 'saint-b');
      expect(loc.section.id, 'sec-b-001');
      await list.close();
      await source.close();
    });

    test('follows changes made elsewhere', () async {
      final source = BookmarksCubit(InMemoryBookmarkStore());
      await source.load();
      final list =
          BookmarkListCubit(source, repoFor(probeFor(searchBook())));
      await pumpEventQueue();
      expect(list.state.status, LoadStatus.empty);

      await source.toggle(
        saintId: 'saint-a',
        sectionId: 'sec-a-001',
        paragraphId: 'p-000001',
        contentVersion: 1,
      );
      await pumpEventQueue();
      expect(list.state.views, hasLength(1));

      await list.remove(list.state.views.single.bookmark.id);
      await pumpEventQueue();
      expect(list.state.status, LoadStatus.empty);
      await list.close();
      await source.close();
    });

    test('a read failure shows the error state', () async {
      final store = FailingBookmarkStore(InMemoryBookmarkStore())
        ..failReads = true;
      final source = BookmarksCubit(store);
      await source.load();
      final list =
          BookmarkListCubit(source, repoFor(probeFor(searchBook())));
      await pumpEventQueue();
      expect(list.state.status, LoadStatus.error);
      await list.close();
      await source.close();
    });
  });
}
