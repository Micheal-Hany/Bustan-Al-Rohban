import '../../../core/content/content_loader.dart';
import '../../../core/content/content_models.dart';

class SaintNotFoundException implements Exception {
  const SaintNotFoundException(this.saintId);

  final String saintId;

  @override
  String toString() => 'SaintNotFoundException: $saintId';
}

/// Where a paragraph currently lives in the installed content.
class ParagraphLocation {
  const ParagraphLocation({
    required this.saint,
    required this.section,
    required this.paragraph,
  });

  final Saint saint;
  final Section section;
  final Paragraph paragraph;
}

/// Read access to the installed book. Loads the manifest once and each saint
/// file on demand, then caches them. Failures are never cached, so a retry
/// really retries.
class LibraryRepository {
  LibraryRepository(this._loader);

  final ContentLoader _loader;
  ContentManifest? _manifestCache;
  final Map<String, Saint> _saintCache = {};

  Future<ContentManifest> manifest() async =>
      _manifestCache ??= await _loader.loadManifest();

  /// Saints in book order.
  Future<List<SaintEntry>> saints() async {
    final m = await manifest();
    return [...m.saints]..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<SaintEntry?> entry(String saintId) async {
    final m = await manifest();
    for (final e in m.saints) {
      if (e.id == saintId) return e;
    }
    return null;
  }

  /// Loads and validates one saint file (cached after the first success).
  Future<Saint> saint(String saintId) async {
    final cached = _saintCache[saintId];
    if (cached != null) return cached;
    final e = await entry(saintId);
    if (e == null) throw SaintNotFoundException(saintId);
    final saint = await _loader.loadSaint(e);
    _saintCache[saintId] = saint;
    return saint;
  }

  /// Finds a paragraph by its stable ID, wherever it currently is in the book
  /// (so references survive re-ordering). [saintHint] is tried first. Returns
  /// null when the paragraph no longer exists. A saint that fails to load is
  /// skipped.
  Future<ParagraphLocation?> locate(
    String paragraphId, {
    String? saintHint,
  }) async {
    final entries = await saints();
    final order = <String>[
      if (saintHint != null && entries.any((e) => e.id == saintHint)) saintHint,
      for (final e in entries)
        if (e.id != saintHint) e.id,
    ];
    for (final id in order) {
      final Saint saint;
      try {
        saint = await this.saint(id);
      } catch (_) {
        continue;
      }
      for (final section in saint.sections) {
        for (final paragraph in section.paragraphs) {
          if (paragraph.id == paragraphId) {
            return ParagraphLocation(
              saint: saint,
              section: section,
              paragraph: paragraph,
            );
          }
        }
      }
    }
    return null;
  }
}
