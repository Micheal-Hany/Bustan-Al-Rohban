import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'reading_progress.dart';

class DriftProgressStore implements ProgressStore {
  DriftProgressStore(this._db);

  final AppDatabase _db;

  ReadingProgress _toDomain(ProgressRow r) => ReadingProgress(
        saintId: r.saintId,
        sectionId: r.sectionId,
        paragraphId: r.paragraphId,
        offset: r.charOffset,
        contentVersion: r.contentVersion,
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(r.updatedAtMs, isUtc: true),
      );

  @override
  Future<void> save(ReadingProgress p) async {
    await _db.into(_db.progressRows).insertOnConflictUpdate(
          ProgressRowsCompanion.insert(
            sectionId: p.sectionId,
            saintId: p.saintId,
            paragraphId: p.paragraphId,
            charOffset: Value(p.offset),
            contentVersion: p.contentVersion,
            updatedAtMs: p.updatedAt.millisecondsSinceEpoch,
          ),
        );
  }

  @override
  Future<ReadingProgress?> forSection(String sectionId) async {
    final row = await (_db.select(_db.progressRows)
          ..where((t) => t.sectionId.equals(sectionId)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<ReadingProgress?> last() async {
    final row = await (_db.select(_db.progressRows)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAtMs)])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }
}
