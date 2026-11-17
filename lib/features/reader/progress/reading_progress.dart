/// Last reading position in a section: paragraph ID plus character offset.
class ReadingProgress {
  const ReadingProgress({
    required this.saintId,
    required this.sectionId,
    required this.paragraphId,
    required this.offset,
    required this.contentVersion,
    required this.updatedAt,
  });

  /// Hints only; the paragraph ID is the identity.
  final String saintId;
  final String sectionId;
  final String paragraphId;
  final int offset;
  final int contentVersion;
  final DateTime updatedAt;

  @override
  String toString() => 'ReadingProgress($sectionId, $paragraphId+$offset)';
}

abstract class ProgressStore {
  /// Inserts or replaces the progress of `progress.sectionId`.
  Future<void> save(ReadingProgress progress);

  Future<ReadingProgress?> forSection(String sectionId);

  /// The most recently updated progress across the book.
  Future<ReadingProgress?> last();
}

/// Memory-only store: tests and the default in widget tests.
class InMemoryProgressStore implements ProgressStore {
  final Map<String, ReadingProgress> _bySection = {};
  final Map<String, int> _sequence = {};
  int _counter = 0;

  @override
  Future<void> save(ReadingProgress progress) async {
    _bySection[progress.sectionId] = progress;
    _sequence[progress.sectionId] = ++_counter;
  }

  @override
  Future<ReadingProgress?> forSection(String sectionId) async =>
      _bySection[sectionId];

  @override
  Future<ReadingProgress?> last() async {
    ReadingProgress? best;
    for (final p in _bySection.values) {
      if (best == null) {
        best = p;
        continue;
      }
      final c = p.updatedAt.compareTo(best.updatedAt);
      if (c > 0 ||
          (c == 0 && _sequence[p.sectionId]! > _sequence[best.sectionId]!)) {
        best = p;
      }
    }
    return best;
  }
}
