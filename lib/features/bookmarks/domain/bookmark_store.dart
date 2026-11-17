import 'dart:math';

import 'bookmark.dart';

abstract class BookmarkStore {
  /// Newest first.
  Future<List<Bookmark>> all();

  /// Adds a bookmark; returns the existing one if the same paragraph and
  /// offset is already bookmarked (idempotent).
  Future<Bookmark> add({
    required String saintId,
    required String sectionId,
    required String paragraphId,
    int offset = 0,
    required int contentVersion,
  });

  /// Returns whether something was removed.
  Future<bool> remove(String id);

  Future<Bookmark?> find(String paragraphId, {int offset = 0});
}

final _random = Random.secure();

/// Random 16-hex-digit ID with a prefix.
String randomId([String prefix = 'bm']) {
  final bytes = List<int>.generate(8, (_) => _random.nextInt(256));
  return '$prefix-${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
}

/// Newest first, ties broken by id (descending) for a stable order.
int compareBookmarksNewestFirst(Bookmark a, Bookmark b) {
  final c = b.createdAt.compareTo(a.createdAt);
  return c != 0 ? c : b.id.compareTo(a.id);
}

/// Memory-only store: used by tests and as the default in widget tests.
/// `main.dart` wires the Drift-backed store.
class InMemoryBookmarkStore implements BookmarkStore {
  InMemoryBookmarkStore({IdGenerator? newId, Clock? clock})
      : _newId = newId ?? randomId,
        _clock = clock ?? DateTime.now;

  final IdGenerator _newId;
  final Clock _clock;
  final List<Bookmark> _items = [];

  @override
  Future<List<Bookmark>> all() async =>
      [..._items]..sort(compareBookmarksNewestFirst);

  @override
  Future<Bookmark?> find(String paragraphId, {int offset = 0}) async {
    for (final b in _items) {
      if (b.paragraphId == paragraphId && b.offset == offset) return b;
    }
    return null;
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
    final b = Bookmark(
      id: _newId(),
      saintId: saintId,
      sectionId: sectionId,
      paragraphId: paragraphId,
      offset: offset,
      contentVersion: contentVersion,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        _clock().millisecondsSinceEpoch,
        isUtc: true,
      ),
    );
    _items.add(b);
    return b;
  }

  @override
  Future<bool> remove(String id) async {
    final before = _items.length;
    _items.removeWhere((b) => b.id == id);
    return _items.length != before;
  }
}
