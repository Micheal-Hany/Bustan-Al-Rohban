import 'dart:io';

import 'package:bustan_al_rohban/core/db/app_database.dart';
import 'package:bustan_al_rohban/features/bookmarks/data/drift_bookmark_store.dart';
import 'package:bustan_al_rohban/features/reader/progress/drift_progress_store.dart';
import 'package:bustan_al_rohban/features/settings/data/drift_prefs_store.dart';
import 'package:bustan_al_rohban/features/settings/domain/reading_prefs.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../features/bookmarks/bookmark_store_contract.dart';
import '../../features/reader/progress/progress_store_contract.dart';
import '../../features/settings/prefs_store_contract.dart';

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

  runPrefsStoreContract(
    'Drift',
    () async => DriftPrefsStore(_memoryDb()),
    skip: _skip,
  );

  group('Drift database', skip: _skip, () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('bustan_db_test');
      addTearDown(() => dir.deleteSync(recursive: true));
    });

    test('schema version is 2', () async {
      final db = _memoryDb();
      expect(db.schemaVersion, 2);
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

    test('corrupt stored preferences fall back to valid values', () async {
      final db = _memoryDb();
      await db.into(db.settingRows).insert(
          SettingRowsCompanion.insert(key: PrefsKeys.textScale, value: 'abc'));
      await db.into(db.settingRows).insert(SettingRowsCompanion.insert(
          key: PrefsKeys.lineSpacing, value: 'enormous'));
      expect(await DriftPrefsStore(db).load(), ReadingPrefs.defaults);
    });

    test('an off-step stored size snaps to the nearest step', () async {
      final db = _memoryDb();
      await db.into(db.settingRows).insert(
          SettingRowsCompanion.insert(key: PrefsKeys.textScale, value: '1.2'));
      expect((await DriftPrefsStore(db).load()).textScale, 1.15);
    });

    test('preferences survive closing and reopening the database file',
        () async {
      final file = File('${dir.path}/prefs.sqlite');
      final db1 = AppDatabase(NativeDatabase(file));
      await DriftPrefsStore(db1).save(const ReadingPrefs(
        textScale: 1.75,
        lineSpacing: LineSpacing.compact,
      ));
      await db1.close();

      final db2 = AppDatabase(NativeDatabase(file));
      addTearDown(db2.close);
      final p = await DriftPrefsStore(db2).load();
      expect(p.textScale, 1.75);
      expect(p.lineSpacing, LineSpacing.compact);
    });

    test('upgrading a version 1 database keeps data and adds settings',
        () async {
      final file = File('${dir.path}/v1.sqlite');
      // Build a database exactly as schema version 1 created it.
      final raw = sqlite3.open(file.path);
      raw.execute('''
        CREATE TABLE bookmarks (
          id TEXT NOT NULL, saint_id TEXT NOT NULL, section_id TEXT NOT NULL,
          paragraph_id TEXT NOT NULL, char_offset INTEGER NOT NULL DEFAULT 0,
          content_version INTEGER NOT NULL, created_at_ms INTEGER NOT NULL,
          PRIMARY KEY (id), UNIQUE (paragraph_id, char_offset));
      ''');
      raw.execute('''
        CREATE TABLE reading_progress (
          section_id TEXT NOT NULL, saint_id TEXT NOT NULL,
          paragraph_id TEXT NOT NULL, char_offset INTEGER NOT NULL DEFAULT 0,
          content_version INTEGER NOT NULL, updated_at_ms INTEGER NOT NULL,
          PRIMARY KEY (section_id));
      ''');
      raw.execute(
          "INSERT INTO bookmarks VALUES ('bm-1','saint-a','sec-a-001','p-000001',0,1,1000)");
      raw.execute(
          "INSERT INTO reading_progress VALUES ('sec-a-001','saint-a','p-000002',0,1,2000)");
      raw.execute('PRAGMA user_version = 1');
      raw.dispose();

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      // Old data is intact.
      final bookmarks = await DriftBookmarkStore(db).all();
      expect(bookmarks.single.id, 'bm-1');
      expect(bookmarks.single.paragraphId, 'p-000001');
      final progress = await DriftProgressStore(db).forSection('sec-a-001');
      expect(progress!.paragraphId, 'p-000002');

      // The new table exists and works.
      final prefs = DriftPrefsStore(db);
      expect(await prefs.load(), ReadingPrefs.defaults);
      await prefs.save(const ReadingPrefs(textScale: 1.3));
      expect((await prefs.load()).textScale, 1.3);
    });
  });
}
