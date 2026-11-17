import 'package:bustan_al_rohban/features/reader/progress/progress_cubit.dart';
import 'package:bustan_al_rohban/features/reader/progress/reading_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import 'progress_store_contract.dart';

class _FailingProgressStore implements ProgressStore {
  @override
  Future<ReadingProgress?> forSection(String sectionId) =>
      throw StateError('read failed');

  @override
  Future<ReadingProgress?> last() => throw StateError('read failed');

  @override
  Future<void> save(ReadingProgress progress) =>
      throw StateError('write failed');
}

void main() {
  group('ProgressCubit', () {
    test('starts with no last position', () {
      expect(ProgressCubit(InMemoryProgressStore()).state.last, isNull);
    });

    test('record saves and updates the last position', () async {
      final store = InMemoryProgressStore();
      final c = ProgressCubit(store,
          clock: () => DateTime.utc(2026, 5, 1, 12));
      await c.record(
        saintId: 'saint-a',
        sectionId: 'sec-a-001',
        paragraphId: 'p-000003',
        contentVersion: 2,
      );
      expect(c.state.last!.paragraphId, 'p-000003');
      final saved = (await store.forSection('sec-a-001'))!;
      expect(saved.paragraphId, 'p-000003');
      expect(saved.contentVersion, 2);
      expect(saved.updatedAt, DateTime.utc(2026, 5, 1, 12));
      await c.close();
    });

    test('load restores the last position saved earlier (restart)', () async {
      final store = InMemoryProgressStore();
      await store.save(progress('sec-a-002', 'p-000004', seconds: 7));
      final c = ProgressCubit(store);
      await c.load();
      expect(c.state.last!.sectionId, 'sec-a-002');
      await c.close();
    });

    test('forSection returns saved progress or null', () async {
      final store = InMemoryProgressStore();
      await store.save(progress('sec-a-001', 'p-000002'));
      final c = ProgressCubit(store);
      expect((await c.forSection('sec-a-001'))!.paragraphId, 'p-000002');
      expect(await c.forSection('sec-zzz'), isNull);
      await c.close();
    });

    test('a failing store never throws into the reader', () async {
      final c = ProgressCubit(_FailingProgressStore());
      await c.load();
      await c.record(
        saintId: 'saint-a',
        sectionId: 'sec-a-001',
        paragraphId: 'p-000001',
        contentVersion: 1,
      );
      expect(await c.forSection('sec-a-001'), isNull);
      expect(c.state.last, isNull);
      await c.close();
    });
  });
}
