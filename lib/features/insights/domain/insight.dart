import 'dart:convert';

import '../../../core/content/content_issue.dart';
import '../../../core/content/content_models.dart';

enum ReviewStatus { draft, approved, rejected }

enum InsightOrigin { aiDraft, human }

/// A prepared (non-book) summary of one section. Never part of the original
/// text; always shown apart from it.
class Insight {
  const Insight({
    required this.id,
    required this.sectionId,
    required this.summary,
    required this.keyPoints,
    required this.spiritualLessons,
    required this.keywords,
    required this.supportingParagraphIds,
    required this.origin,
    required this.reviewStatus,
    this.reviewedBy,
    this.reviewedAt,
    this.fixture = false,
  });

  final String id;
  final String sectionId;
  final String summary;
  final List<String> keyPoints;
  final List<String> spiritualLessons;
  final List<String> keywords;
  final List<String> supportingParagraphIds;
  final InsightOrigin origin;
  final ReviewStatus reviewStatus;
  final String? reviewedBy;
  final String? reviewedAt;
  final bool fixture;

  bool get isApproved => reviewStatus == ReviewStatus.approved;
}

class InsightParseResult {
  const InsightParseResult(this.insights, this.issues);

  /// Valid insights only; an insight with an error is dropped entirely.
  final List<Insight> insights;
  final List<ContentIssue> issues;

  bool get hasErrors => issues.any((i) => i.isError);
}

/// Parses and validates `insights/<saintId>.insights.json` against the saint
/// it belongs to (CONTENT_SCHEMA section 4 and validation rule 7).
InsightParseResult parseInsights(
  String text,
  Saint saint, {
  String file = 'insights.json',
}) {
  final issues = <ContentIssue>[];
  void error(String code, String path, String message) => issues.add(
      ContentIssue(
          severity: IssueSeverity.error,
          code: code,
          file: file,
          path: path,
          message: message));

  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } catch (e) {
    error('invalid-json', '', 'The file is not valid JSON.');
    return InsightParseResult(const [], issues);
  }
  if (decoded is! Map) {
    error('wrong-type', '', 'The file must contain a JSON object.');
    return InsightParseResult(const [], issues);
  }
  if (decoded['schemaVersion'] != 1) {
    error('unsupported-schema', 'schemaVersion',
        'Unsupported schemaVersion (this app reads 1).');
    return InsightParseResult(const [], issues);
  }
  if (decoded['saintId'] != saint.id) {
    error('id-mismatch', 'saintId',
        'saintId "${decoded['saintId']}" differs from "${saint.id}".');
    return InsightParseResult(const [], issues);
  }
  final raw = decoded['insights'];
  if (raw is! List) {
    error('missing-field', 'insights', 'Field "insights" must be a list.');
    return InsightParseResult(const [], issues);
  }

  final sectionIds = {for (final s in saint.sections) s.id};
  final paragraphIds = {
    for (final s in saint.sections)
      for (final p in s.paragraphs) p.id,
  };
  final seen = <String>{};
  final out = <Insight>[];

  for (var i = 0; i < raw.length; i++) {
    final path = 'insights[$i]';
    final before = issues.length;
    final m = raw[i];
    if (m is! Map) {
      error('wrong-type', path, 'Each insight must be an object.');
      continue;
    }

    String? str(String key, {bool required = true}) {
      final v = m[key];
      if (v is String && v.trim().isNotEmpty) return v;
      if (v == null && !required) return null;
      error('missing-field', '$path.$key',
          'Field "$key" must be a non-empty string.');
      return null;
    }

    List<String> strings(String key, {bool required = false}) {
      final v = m[key];
      if (v == null) {
        if (required) {
          error('missing-field', '$path.$key', 'Field "$key" is required.');
        }
        return const [];
      }
      if (v is List && v.every((e) => e is String && e.trim().isNotEmpty)) {
        return v.cast<String>();
      }
      error('wrong-type', '$path.$key',
          'Field "$key" must be a list of non-empty strings.');
      return const [];
    }

    final id = str('id');
    final sectionId = str('sectionId');
    final summary = str('summary');
    final keyPoints = strings('keyPoints');
    final lessons = strings('spiritualLessons');
    final keywords = strings('keywords');
    final support = strings('supportingParagraphIds', required: true);
    final originRaw = m['origin'];
    final statusRaw = m['reviewStatus'];

    InsightOrigin? origin;
    if (originRaw == 'ai_draft') origin = InsightOrigin.aiDraft;
    if (originRaw == 'human') origin = InsightOrigin.human;
    if (origin == null) {
      error('bad-origin', '$path.origin',
          'origin must be "ai_draft" or "human".');
    }
    ReviewStatus? status;
    for (final s in ReviewStatus.values) {
      if (s.name == statusRaw) status = s;
    }
    if (status == null) {
      error('bad-review-status', '$path.reviewStatus',
          'reviewStatus must be draft, approved or rejected.');
    }

    if (id != null && !seen.add(id)) {
      error('duplicate-id', '$path.id', 'Duplicate insight id "$id".');
    }
    if (sectionId != null && !sectionIds.contains(sectionId)) {
      error('insight-missing-section', '$path.sectionId',
          'Section "$sectionId" does not exist in ${saint.id}.');
    }
    for (final p in support) {
      if (!paragraphIds.contains(p)) {
        error('insight-missing-paragraph', '$path.supportingParagraphIds',
            'Paragraph "$p" does not exist in ${saint.id}.');
      }
    }
    if (status == ReviewStatus.approved && m['reviewedBy'] == null) {
      error('approved-without-reviewer', '$path.reviewedBy',
          'An approved insight must name who reviewed it.');
    }

    if (issues.length > before) continue;
    out.add(Insight(
      id: id!,
      sectionId: sectionId!,
      summary: summary!,
      keyPoints: keyPoints,
      spiritualLessons: lessons,
      keywords: keywords,
      supportingParagraphIds: support,
      origin: origin!,
      reviewStatus: status!,
      reviewedBy: m['reviewedBy'] as String?,
      reviewedAt: m['reviewedAt'] as String?,
      fixture: m['fixture'] == true,
    ));
  }
  return InsightParseResult(out, issues);
}

/// The release rule: only approved insights are shown, unless
/// [showUnapproved] (debug builds) is on. Rejected insights are never shown.
List<Insight> visibleInsights(
  List<Insight> all, {
  required bool showUnapproved,
}) =>
    [
      for (final i in all)
        if (i.isApproved ||
            (showUnapproved && i.reviewStatus == ReviewStatus.draft))
          i,
    ];
