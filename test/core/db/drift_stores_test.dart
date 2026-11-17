import 'dart:io';

import 'package:bustan_al_rohban/core/db/app_database.dart';
import 'package:bustan_al_rohban/features/bookmarks/data/drift_bookmark_store.dart';
import 'package:bustan_al_rohban/features/reader/progress/drift_progress_store.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../features/bookmarks/bookmark_store_contract.dart';
import '../../features/reader/progress/progress_store_contract.dart';

/// These tests open a real SQLite database. On a machine without the sqlite3
/// native library (for example Windows without sqlite3.dll) they are skipped
/// with a message instead of failing; see the README for how to enable them.
bool _sqliteAvailable() {
  try {
    sqlite3.openInMemory().dispose();
    return true;
  } catch (_) {
    return false;
  }
}

final Object? _skip = _sqliteAvailable()
    ? null
    : 'sqlite3 native library not found (see README, Task 5)';

AppDatabase _memoryDb() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

void main() {
  runBookmarkStoreContract(
    'Drift',
    (newId, clock) async =>
        DriftBookmarkStore(_memoryDb(), newId: newId, clock: clock),
    skip: _skip,
  );

  runProgressStoreContract(
    'Drift',
    () async => DriftProgressStore(_memoryDb()),
    skip: _skip,
  );

  group('Drift database', skip: _skip, () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('bustan_db_test');
      addTearDown(() => dir.deleteSync(recursive: true));
    });

    test('schema version is 1', () async {
      final db = _memoryDb();
      expect(db.schemaVersion, 1);
    });

    test('data survives closing and reopening the database file', () async {
      final file = File('${dir.path}/test.sqlite');

      final db1 = AppDatabase(NativeDatabase(file));
      await DriftBookmarkStore(db1).add(
        saintId: 'saint-a',
        sectionId: 'sec-a-001',
        paragraphId: 'p-000001',
        offset: 7,
        contentVersion: 1,
      );
      await DriftProgressStore(db1).save(
          progress('sec-a-001', 'p-000002', offset: 3, seconds: 4));
      await db1.close();

      final db2 = AppDatabase(NativeDatabase(file));
      addTearDown(db2.close);
      final bookmarks = await DriftBookmarkStore(db2).all();
      expect(bookmarks.single.paragraphId, 'p-000001');
      expect(bookmarks.single.offset, 7);
      final p = await DriftProgressStore(db2).forSection('sec-a-001');
      expect(p!.paragraphId, 'p-000002');
      expect(p.offset, 3);
    });

    test('the database enforces one bookmark per paragraph and offset',
        () async {
      final db = _memoryDb();
      Future<void> insert(String id) => db.into(db.bookmarkRows).insert(
            BookmarkRowsCompanion.insert(
              id: id,
              saintId: 's',
              sectionId: 'c',
              paragraphId: 'p-000001',
              contentVersion: 1,
              createdAtMs: 1,
            ),
          );
      await insert('a');
      await expectLater(insert('b'), throwsA(anything));
    });

    test('foreign keys are switched on', () async {
      final db = _memoryDb();
      final row =
          await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(row.data.values.first, 1);
    });

    test('Arabic and diacritics in IDs and hints round-trip', () async {
      final db = _memoryDb();
      final store = DriftBookmarkStore(db);
      await store.add(
        saintId: 'saint-أبونا',
        sectionId: 'sec-ب',
        paragraphId: 'p-000001',
        contentVersion: 1,
      );
      expect((await store.all()).single.saintId, 'saint-أبونا');
    });
  });
}
