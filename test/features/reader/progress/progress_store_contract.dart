import 'package:bustan_al_rohban/features/reader/progress/reading_progress.dart';
import 'package:flutter_test/flutter_test.dart';

ReadingProgress progress(
  String sectionId,
  String paragraphId, {
  int offset = 0,
  int seconds = 0,
  String saintId = 'saint-a',
  int contentVersion = 1,
}) =>
    ReadingProgress(
      saintId: saintId,
      sectionId: sectionId,
      paragraphId: paragraphId,
      offset: offset,
      contentVersion: contentVersion,
      updatedAt: DateTime.utc(2026, 1, 1).add(Duration(seconds: seconds)),
    );

/// Behavior every [ProgressStore] must have (in-memory and Drift).
void runProgressStoreContract(
  String label,
  Future<ProgressStore> Function() create, {
  Object? skip,
}) {
  group('ProgressStore contract: $label', skip: skip, () {
    late ProgressStore store;

    setUp(() async {
      store = await create();
    });

    test('starts empty', () async {
      expect(await store.last(), isNull);
      expect(await store.forSection('sec-a-001'), isNull);
    });

    test('save then read back every field', () async {
      await store.save(progress('sec-a-001', 'p-000007',
          offset: 15, seconds: 5, contentVersion: 2));
      final p = (await store.forSection('sec-a-001'))!;
      expect(p.saintId, 'saint-a');
      expect(p.sectionId, 'sec-a-001');
      expect(p.paragraphId, 'p-000007');
      expect(p.offset, 15);
      expect(p.contentVersion, 2);
      expect(p.updatedAt.millisecondsSinceEpoch,
          DateTime.utc(2026, 1, 1, 0, 0, 5).millisecondsSinceEpoch);
    });

    test('saving again replaces the section position', () async {
      await store.save(progress('sec-a-001', 'p-000001', seconds: 1));
      await store.save(progress('sec-a-001', 'p-000009', seconds: 2));
      expect((await store.forSection('sec-a-001'))!.paragraphId, 'p-000009');
    });

    test('sections are independent', () async {
      await store.save(progress('sec-a-001', 'p-000001', seconds: 1));
      await store.save(progress('sec-a-002', 'p-000004', seconds: 2));
      expect((await store.forSection('sec-a-001'))!.paragraphId, 'p-000001');
      expect((await store.forSection('sec-a-002'))!.paragraphId, 'p-000004');
    });

    test('last is the most recently updated section', () async {
      await store.save(progress('sec-a-001', 'p-000001', seconds: 1));
      await store.save(progress('sec-a-002', 'p-000004', seconds: 5));
      await store.save(progress('sec-b-001', 'p-000008', seconds: 3));
      expect((await store.last())!.sectionId, 'sec-a-002');
    });

    test('updating an older section makes it the last', () async {
      await store.save(progress('sec-a-001', 'p-000001', seconds: 1));
      await store.save(progress('sec-a-002', 'p-000004', seconds: 2));
      await store.save(progress('sec-a-001', 'p-000002', seconds: 9));
      final last = (await store.last())!;
      expect(last.sectionId, 'sec-a-001');
      expect(last.paragraphId, 'p-000002');
    });
  });
}
