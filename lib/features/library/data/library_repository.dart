import '../../../core/content/content_loader.dart';
import '../../../core/content/content_models.dart';

class SaintNotFoundException implements Exception {
  const SaintNotFoundException(this.saintId);

  final String saintId;

  @override
  String toString() => 'SaintNotFoundException: $saintId';
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
}
