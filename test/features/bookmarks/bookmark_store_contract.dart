import 'package:bustan_al_rohban/features/bookmarks/domain/bookmark.dart';
import 'package:bustan_al_rohban/features/bookmarks/domain/bookmark_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Behavior every [BookmarkStore] must have. Run against the in-memory store
/// and against the Drift store, so the fake cannot drift from the real one.
void runBookmarkStoreContract(
  String label,
  Future<BookmarkStore> Function(IdGenerator newId, Clock clock) create, {
  Object? skip,
}) {
  group('BookmarkStore contract: $label', skip: skip, () {
    late int n;
    late DateTime t;
    String newId() => 'bm-${(++n).toString().padLeft(4, '0')}';
    DateTime clock() {
      t = t.add(const Duration(seconds: 1));
      return t;
    }

    late BookmarkStore store;

    setUp(() async {
      n = 0;
      t = DateTime.utc(2026, 1, 1);
      store = await create(newId, clock);
    });

    Future<Bookmark> add(String paragraphId, {int offset = 0}) => store.add(
          saintId: 'saint-a',
          sectionId: 'sec-a-001',
          paragraphId: paragraphId,
          offset: offset,
          contentVersion: 3,
        );

    test('starts empty', () async {
      expect(await store.all(), isEmpty);
    });

    test('add stores every field', () async {
      final b = await add('p-000001', offset: 42);
      expect(b.id, 'bm-0001');
      expect(b.saintId, 'saint-a');
      expect(b.sectionId, 'sec-a-001');
      expect(b.paragraphId, 'p-000001');
      expect(b.offset, 42);
      expect(b.contentVersion, 3);
      expect(b.createdAt, DateTime.utc(2026, 1, 1, 0, 0, 1));

      final read = (await store.all()).single;
      expect(read.id, b.id);
      expect(read.paragraphId, 'p-000001');
      expect(read.offset, 42);
      expect(read.contentVersion, 3);
      expect(read.createdAt.millisecondsSinceEpoch,
          b.createdAt.millisecondsSinceEpoch);
    });

    test('adding the same paragraph and offset is idempotent', () async {
      final a = await add('p-000001');
      final b = await add('p-000001');
      expect(b.id, a.id);
      expect(await store.all(), hasLength(1));
    });

    test('the same paragraph at another offset is a separate bookmark',
        () async {
      final a = await add('p-000001');
      final b = await add('p-000001', offset: 10);
      expect(b.id, isNot(a.id));
      expect(await store.all(), hasLength(2));
    });

    test('find matches paragraph and offset', () async {
      final a = await add('p-000001');
      expect((await store.find('p-000001'))!.id, a.id);
      expect(await store.find('p-000001', offset: 5), isNull);
      expect(await store.find('p-000002'), isNull);
    });

    test('all returns newest first', () async {
      await add('p-000001');
      await add('p-000002');
      await add('p-000003');
      final ids = (await store.all()).map((b) => b.paragraphId).toList();
      expect(ids, ['p-000003', 'p-000002', 'p-000001']);
    });

    test('remove deletes only that bookmark', () async {
      final a = await add('p-000001');
      await add('p-000002');
      expect(await store.remove(a.id), isTrue);
      final left = await store.all();
      expect(left.map((b) => b.paragraphId), ['p-000002']);
      expect(await store.find('p-000001'), isNull);
    });

    test('remove of an unknown id returns false', () async {
      expect(await store.remove('nope'), isFalse);
    });

    test('a removed bookmark can be added again', () async {
      final a = await add('p-000001');
      await store.remove(a.id);
      final b = await add('p-000001');
      expect(b.id, isNot(a.id));
      expect(await store.all(), hasLength(1));
    });
  });
}
