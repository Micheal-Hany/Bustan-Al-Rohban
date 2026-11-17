import 'dart:convert';

import 'package:bustan_al_rohban/core/content/content_loader.dart';
import 'package:bustan_al_rohban/core/content/content_models.dart';
import 'package:bustan_al_rohban/core/content/content_validator.dart';
import 'package:bustan_al_rohban/features/library/data/library_repository.dart';

import '../../core/content/test_support.dart';
import '../library/library_test_support.dart';

Map<String, dynamic> insightJson({
  String id = 'ins-a-001',
  String sectionId = 'sec-a-001',
  String summary = 'ملخص',
  List<String> keyPoints = const ['نقطة ١', 'نقطة ٢'],
  List<String> lessons = const ['درس'],
  List<String> keywords = const ['كلمة'],
  List<String> support = const ['p-000001', 'p-000002'],
  String origin = 'ai_draft',
  String status = 'approved',
  String? reviewedBy = 'owner',
}) =>
    {
      'id': id,
      'sectionId': sectionId,
      'summary': summary,
      'keyPoints': keyPoints,
      'spiritualLessons': lessons,
      'keywords': keywords,
      'supportingParagraphIds': support,
      'origin': origin,
      'reviewStatus': status,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      'fixture': true,
    };

String insightsFile(List<Map<String, dynamic>> insights,
        {String saintId = 'saint-a'}) =>
    jsonEncode({
      'schemaVersion': 1,
      'saintId': saintId,
      'contentVersion': 1,
      'insights': insights,
    });

/// saint-a of [twoSaintBook]: sec-a-001 (p-000001, p-000002), sec-a-002
/// (p-000003).
Saint saintA() {
  final text = twoSaintBook().files['saints/saint-a.json']!;
  return const ContentValidator()
      .parseSaint(text, file: 'saints/saint-a.json')
      .saint!;
}

/// A repository over [twoSaintBook] plus an optional insights file for
/// saint-a. [reads] counts how often the insights file was read.
({LibraryRepository repo, ProbeSource source}) insightRepo(
  String? insightsText, {
  bool showUnapproved = false,
}) {
  final book = twoSaintBook();
  final source = ProbeSource(InMemoryContentSource({
    'manifest.json': book.manifestJson,
    ...book.files,
    if (insightsText != null)
      'insights/saint-a.insights.json': insightsText,
  }));
  return (
    repo: LibraryRepository(ContentLoader(source),
        showUnapproved: showUnapproved),
    source: source,
  );
}
