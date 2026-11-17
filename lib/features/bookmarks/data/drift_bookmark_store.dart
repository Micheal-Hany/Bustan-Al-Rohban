import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/bookmark.dart';
import '../domain/bookmark_store.dart';

class DriftBookmarkStore implements BookmarkStore {
  DriftBookmarkStore(this._db, {IdGenerator? newId, Clock? clock})
      : _newId = newId ?? randomId,
        _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final IdGenerator _newId;
  final Clock _clock;

  Bookmark _toDomain(BookmarkRow r) => Bookmark(
        id: r.id,
        saintId: r.saintId,
        sectionId: r.sectionId,
        paragraphId: r.paragraphId,
        offset: r.charOffset,
        contentVersion: r.contentVersion,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(r.createdAtMs, isUtc: true),
      );

  @override
  Future<List<Bookmark>> all() async {
    final rows = await (_db.select(_db.bookmarkRows)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAtMs),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Bookmark?> find(String paragraphId, {int offset = 0}) async {
    final row = await (_db.select(_db.bookmarkRows)
          ..where(
            (t) => t.paragraphId.equals(paragraphId) &
                t.charOffset.equals(offset),
          ))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<Bookmark> add({
    required String saintId,
    required String sectionId,
    required String paragraphId,
    int offset = 0,
    required int contentVersion,
  }) async {
    final existing = await find(paragraphId, offset: offset);
    if (existing != null) return existing;
    final id = _newId();
    final createdAtMs = _clock().millisecondsSinceEpoch;
    await _db.into(_db.bookmarkRows).insert(BookmarkRowsCompanion.insert(
          id: id,
          saintId: saintId,
          sectionId: sectionId,
          paragraphId: paragraphId,
          charOffset: Value(offset),
          contentVersion: contentVersion,
          createdAtMs: createdAtMs,
        ));
    return Bookmark(
      id: id,
      saintId: saintId,
      sectionId: sectionId,
      paragraphId: paragraphId,
      offset: offset,
      contentVersion: contentVersion,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs, isUtc: true),
    );
  }

  @override
  Future<bool> remove(String id) async {
    final count =
        await (_db.delete(_db.bookmarkRows)..where((t) => t.id.equals(id)))
            .go();
    return count > 0;
  }
}
