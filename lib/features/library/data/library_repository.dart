import '../../../core/content/content_loader.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

import '../../../core/content/content_issue.dart';
import '../../../core/content/content_models.dart';
import '../../../core/content/fixture_gate.dart';
import '../../insights/domain/insight.dart';

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
  /// [showUnapproved] shows draft insights (debug builds only by default).
  ///
  /// [allowFixture] says whether FAKE content may be shown. By default it is
  /// allowed except in release builds (see `fixture_gate.dart`).
  LibraryRepository(
    this._loader, {
    bool? showUnapproved,
    bool? allowFixture,
  })  : showUnapproved = showUnapproved ?? !kReleaseMode,
        _allowFixture = allowFixture ??
            fixtureAllowed(
              release: kReleaseMode,
              override: allowFixtureInReleaseFlag,
            );

  final ContentLoader _loader;
  final bool showUnapproved;
  final bool _allowFixture;
  final Map<String, InsightParseResult> _insightCache = {};

  /// Problems found in insight files (for the owner; never shown to readers).
  final List<ContentIssue> insightIssues = [];
  ContentManifest? _manifestCache;
  final Map<String, Saint> _saintCache = {};

  Future<ContentManifest> manifest() async {
    final cached = _manifestCache;
    if (cached != null) return cached;
    final loaded = await _loader.loadManifest();
    enforceFixtureGate(loaded, allowed: _allowFixture);
    return _manifestCache = loaded;
  }

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

  /// Insights of one section that may be shown (release rule applied).
  /// An invalid or unreadable insights file yields none and is recorded in
  /// [insightIssues]; it never breaks reading.
  Future<List<Insight>> insightsFor(Saint saint, String sectionId) async {
    var result = _insightCache[saint.id];
    if (result == null) {
      try {
        result = await _loader.loadInsights(saint);
      } catch (e) {
        result = InsightParseResult(const [], [
          ContentIssue(
            severity: IssueSeverity.error,
            code: 'insights-unreadable',
            file: 'insights/${saint.id}.insights.json',
            message: '$e',
          ),
        ]);
      }
      _insightCache[saint.id] = result;
      insightIssues.addAll(result.issues);
    }
    // An invalid file shows nothing at all (all-or-nothing, safest).
    if (result.hasErrors) return const [];
    return [
      for (final i in visibleInsights(result.insights,
          showUnapproved: showUnapproved))
        if (i.sectionId == sectionId) i,
    ];
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
