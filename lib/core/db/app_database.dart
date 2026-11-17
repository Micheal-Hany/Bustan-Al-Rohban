import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// Bookmarks. A bookmark points at a paragraph ID plus a character offset
/// inside it, never at a list position, so it survives content re-ordering.
/// `saintId` / `sectionId` are only hints for fast lookup.
@DataClassName('BookmarkRow')
class BookmarkRows extends Table {
  @override
  String get tableName => 'bookmarks';

  TextColumn get id => text()();
  TextColumn get saintId => text()();
  TextColumn get sectionId => text()();
  TextColumn get paragraphId => text()();
  IntColumn get charOffset => integer().withDefault(const Constant(0))();

  /// The content version the bookmark was created under.
  IntColumn get contentVersion => integer()();

  /// Milliseconds since the Unix epoch (UTC).
  IntColumn get createdAtMs => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {paragraphId, charOffset},
      ];
}

/// Last reading position per section (paragraph anchor plus offset).
@DataClassName('ProgressRow')
class ProgressRows extends Table {
  @override
  String get tableName => 'reading_progress';

  TextColumn get sectionId => text()();
  TextColumn get saintId => text()();
  TextColumn get paragraphId => text()();
  IntColumn get charOffset => integer().withDefault(const Constant(0))();
  IntColumn get contentVersion => integer()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column> get primaryKey => {sectionId};
}

/// Simple key/value settings (reading preferences, later others).
@DataClassName('SettingRow')
class SettingRows extends Table {
  @override
  String get tableName => 'app_settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [BookmarkRows, ProgressRows, SettingRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Bump on every table change and add a step in [migration]. See
  /// docs/DB_MIGRATIONS.md.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2 adds the settings table; existing data is untouched.
            await m.createTable(settingRows);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
