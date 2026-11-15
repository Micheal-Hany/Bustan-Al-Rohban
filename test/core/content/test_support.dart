import 'dart:convert';
import 'dart:io';

import 'package:bustan_al_rohban/core/content/content_hasher.dart';
import 'package:bustan_al_rohban/core/content/content_issue.dart';
import 'package:bustan_al_rohban/core/content/content_models.dart';
import 'package:bustan_al_rohban/core/content/content_source.dart';
import 'package:bustan_al_rohban/core/content/content_validator.dart';

/// Content source backed by a map; a missing key throws like a missing asset.
class InMemoryContentSource implements ContentSource {
  InMemoryContentSource(this.files);

  final Map<String, String> files;

  @override
  Future<String> readString(String relativePath) async {
    final text = files[relativePath];
    if (text == null) throw StateError('No such file: $relativePath');
    return text;
  }
}

/// Reads real files from disk (flutter test runs from the project root).
class DiskContentSource implements ContentSource {
  DiskContentSource(this.root);

  final String root;

  @override
  Future<String> readString(String relativePath) =>
      File('$root/$relativePath').readAsString();
}

Map<String, dynamic> paraJson({
  String id = 'p-000001',
  int order = 1,
  Object? page = 1,
  String text = 'نص الفقرة',
  String? kind = 'body',
}) {
  return {
    'id': id,
    'order': order,
    if (kind != null) 'kind': kind,
    'page': page,
    'text': text,
  };
}

Map<String, dynamic> sectionJson({
  String id = 'sec-a-001',
  int order = 1,
  String title = 'عنوان القسم',
  List<Map<String, dynamic>>? paragraphs,
}) {
  final ps = paragraphs ?? [paraJson()];
  int? start;
  int? end;
  if (ps.isNotEmpty && ps.every((p) => p['page'] is int)) {
    start = ps.first['page'] as int;
    end = ps.last['page'] as int;
  }
  return {
    'id': id,
    'title': title,
    'order': order,
    'pageStart': start,
    'pageEnd': end,
    'paragraphs': ps,
  };
}

Map<String, dynamic> saintJson({
  String id = 'saint-a',
  int order = 1,
  String title = 'القديس',
  List<String> aliases = const ['اسم آخر'],
  List<Map<String, dynamic>>? sections,
}) {
  return {
    'schemaVersion': 1,
    'id': id,
    'title': title,
    'order': order,
    'aliases': aliases,
    'sections': sections ?? [sectionJson()],
  };
}

class TestBook {
  TestBook(this.manifest, this.files);

  final Map<String, dynamic> manifest;
  final Map<String, String> files;

  String get manifestJson => jsonEncode(manifest);
}

/// Builds a consistent manifest (counts and hash computed) for the given saint
/// JSON maps. Pass [hashOverride] / [countOverride] to create inconsistencies.
TestBook buildBook(
  List<Map<String, dynamic>> saints, {
  bool fixture = false,
  String? hashOverride,
  int? sectionCountOverride,
}) {
  const validator = ContentValidator();
  final files = <String, String>{};
  final entries = <Map<String, dynamic>>[];
  final parsed = <Saint>[];
  for (final s in saints) {
    final file = 'saints/${s['id']}.json';
    final text = jsonEncode(s);
    files[file] = text;
    final result = validator.parseSaint(text, file: file);
    final saint = result.saint;
    if (saint != null) parsed.add(saint);
    final sections = s['sections'] as List;
    var paragraphs = 0;
    for (final sec in sections) {
      paragraphs += ((sec as Map)['paragraphs'] as List).length;
    }
    entries.add({
      'id': s['id'],
      'title': s['title'],
      'order': s['order'],
      'aliases': s['aliases'],
      'file': file,
      'sectionCount': sectionCountOverride ?? sections.length,
      'paragraphCount': paragraphs,
    });
  }
  final hash = hashOverride ?? ContentHasher.hash(parsed);
  return TestBook({
    'schemaVersion': 1,
    'contentVersion': 1,
    'bookId': 'test-book',
    'title': 'كتاب',
    'language': 'ar',
    'fixture': fixture,
    'edition': {'title': 'طبعة'},
    'saints': entries,
    'contentHash': hash,
  }, files);
}

List<String> errorCodes(ValidationReport report) =>
    report.errors.map((e) => e.code).toList();

List<String> warningCodes(ValidationReport report) =>
    report.warnings.map((e) => e.code).toList();
