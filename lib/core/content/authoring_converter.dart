import 'dart:convert';

import 'content_hasher.dart';
import 'content_issue.dart';
import 'content_models.dart';
import 'content_validator.dart';
import 'id_registry.dart';

final _pageMarker = RegExp(r'^\[p\.(\d+|\?)\]$');

class ConvertedBook {
  const ConvertedBook({
    required this.manifest,
    required this.saintFiles,
    required this.registry,
    required this.issues,
  });

  final Map<String, dynamic> manifest;

  /// Saint JSON keyed by manifest file path, e.g. `saints/saint-x.json`.
  final Map<String, Map<String, dynamic>> saintFiles;
  final IdRegistry registry;

  /// Warnings and errors from conversion and from validating the output.
  final List<ContentIssue> issues;

  ValidationReport get report => ValidationReport(issues);
}

class _ConvertedSaint {
  _ConvertedSaint(this.json, this.issues);

  final Map<String, dynamic> json;
  final List<ContentIssue> issues;
}

class _SectionBuilder {
  _SectionBuilder(this.title, this.number);

  final String title;
  final int number;
  final List<Map<String, dynamic>> rawParagraphs = [];
}

/// Converts the owner's authoring text files (see `docs/CONTENT_SCHEMA.md`
/// section 2) into schema JSON. Original text is never modified: only the
/// leading and trailing whitespace of a whole paragraph is trimmed.
class AuthoringConverter {
  const AuthoringConverter({
    ContentValidator validator = const ContentValidator(),
  }) : _validator = validator;

  final ContentValidator _validator;

  /// [saintTexts] maps file name (e.g. `001-saint-a.txt`) to its text. Saints
  /// are ordered by file name.
  ConvertedBook convertBook({
    required String bookText,
    required Map<String, String> saintTexts,
    required IdRegistry registry,
    int contentVersion = 1,
  }) {
    final issues = <ContentIssue>[];
    final meta = _parseBookMeta(bookText, issues);

    final fileNames = saintTexts.keys.toList()..sort();
    final saintFiles = <String, Map<String, dynamic>>{};
    final entries = <Map<String, dynamic>>[];
    for (var i = 0; i < fileNames.length; i++) {
      final name = fileNames[i];
      final converted =
          _convertSaint(saintTexts[name]!, name, i + 1, registry);
      issues.addAll(converted.issues);
      final json = converted.json;
      final id = json['id'] as String;
      final file = 'saints/$id.json';
      saintFiles[file] = json;
      final sections = json['sections'] as List<Map<String, dynamic>>;
      var paragraphs = 0;
      for (final s in sections) {
        paragraphs += (s['paragraphs'] as List).length;
      }
      entries.add({
        'id': id,
        'title': json['title'],
        'order': json['order'],
        'aliases': json['aliases'],
        'file': file,
        'sectionCount': sections.length,
        'paragraphCount': paragraphs,
      });
    }

    for (final id in registry.retiredIds()) {
      issues.add(ContentIssue(
        severity: IssueSeverity.warning,
        code: 'paragraph-retired',
        file: 'id-registry.json',
        message: 'Paragraph $id was not found in this import (edited, moved '
            'or removed). Bookmarks pointing to it will be orphaned. If it '
            'was only a correction, update the registry by hand to keep the '
            'ID.',
      ));
    }

    final edition = <String, dynamic>{};
    const editionKeys = {
      'edition': 'title',
      'author': 'author',
      'publisher': 'publisher',
      'year': 'year',
      'attribution': 'attribution',
    };
    editionKeys.forEach((from, to) {
      final v = meta[from];
      if (v != null && v.isNotEmpty) edition[to] = v;
    });

    final manifest = <String, dynamic>{
      'schemaVersion': 1,
      'contentVersion': contentVersion,
      'bookId': meta['id'] ?? '',
      'title': meta['title'] ?? '',
      'language': meta['language'] ?? 'ar',
      'fixture': (meta['fixture'] ?? 'false').toLowerCase() == 'true',
      'edition': edition,
      'saints': entries,
      'contentHash': '',
    };

    // Hash the parsed output, then validate the whole book.
    final encodedFiles = {
      for (final e in saintFiles.entries) e.key: jsonEncode(e.value),
    };
    final parsedSaints = <Saint>[];
    for (final e in encodedFiles.entries) {
      final parsed = _validator.parseSaint(e.value, file: e.key);
      final saint = parsed.saint;
      if (saint != null) parsedSaints.add(saint);
    }
    manifest['contentHash'] = parsedSaints.length == encodedFiles.length
        ? ContentHasher.hash(parsedSaints)
        : 'sha256:unavailable';
    final finalResult = _validator.validateBook(
      manifestJson: jsonEncode(manifest),
      saintJsonByFile: encodedFiles,
    );
    issues.addAll(finalResult.report.issues);

    return ConvertedBook(
      manifest: manifest,
      saintFiles: saintFiles,
      registry: registry,
      issues: issues,
    );
  }

  Map<String, String> _parseBookMeta(String text, List<ContentIssue> issues) {
    final meta = <String, String>{};
    var seenMarker = false;
    final lines = _lines(text);
    for (var i = 0; i < lines.length; i++) {
      final t = lines[i].trim();
      if (t.isEmpty) continue;
      if (!seenMarker) {
        if (t == '@book') {
          seenMarker = true;
        } else {
          issues.add(ContentIssue(
            severity: IssueSeverity.error,
            code: 'missing-book-header',
            file: 'book.txt',
            line: i + 1,
            message: 'book.txt must start with @book.',
          ));
          return meta;
        }
        continue;
      }
      final idx = t.indexOf(':');
      if (idx <= 0) {
        issues.add(ContentIssue(
          severity: IssueSeverity.warning,
          code: 'bad-header-line',
          file: 'book.txt',
          line: i + 1,
          message: 'Expected "key: value".',
        ));
        continue;
      }
      meta[t.substring(0, idx).trim().toLowerCase()] =
          t.substring(idx + 1).trim();
    }
    for (final key in ['id', 'title', 'language']) {
      if ((meta[key] ?? '').isEmpty) {
        issues.add(ContentIssue(
          severity: IssueSeverity.error,
          code: 'missing-field',
          file: 'book.txt',
          message: 'book.txt is missing "$key".',
        ));
      }
    }
    return meta;
  }

  List<String> _lines(String text) {
    var t = text;
    if (t.isNotEmpty && t.codeUnitAt(0) == 0xFEFF) t = t.substring(1);
    return t.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  }

  _ConvertedSaint _convertSaint(
    String text,
    String fileName,
    int order,
    IdRegistry registry,
  ) {
    final issues = <ContentIssue>[];
    void err(String code, int? line, String message) => issues.add(ContentIssue(
          severity: IssueSeverity.error,
          code: code,
          file: fileName,
          line: line,
          message: message,
        ));
    void warn(String code, int? line, String message) =>
        issues.add(ContentIssue(
          severity: IssueSeverity.warning,
          code: code,
          file: fileName,
          line: line,
          message: message,
        ));

    final header = <String, String>{};
    final sections = <_SectionBuilder>[];
    _SectionBuilder? current;
    int? currentPage;
    final buffer = <String>[];
    int? bufferPage;

    void flush() {
      if (buffer.isEmpty) return;
      final paragraphText = buffer.join('\n').trim();
      buffer.clear();
      if (paragraphText.isEmpty) return;
      current?.rawParagraphs.add({
        'kind': 'body',
        'page': bufferPage,
        'text': paragraphText,
      });
    }

    var seenSaintMarker = false;
    var inHeader = false;
    final lines = _lines(text);
    for (var i = 0; i < lines.length; i++) {
      final lineNo = i + 1;
      final line = lines[i];
      final t = line.trim();

      if (!seenSaintMarker) {
        if (t.isEmpty) continue;
        if (t == '@saint') {
          seenSaintMarker = true;
          inHeader = true;
          continue;
        }
        err('missing-saint-header', lineNo, 'File must start with @saint.');
        break;
      }

      if (inHeader) {
        if (t.isEmpty) {
          inHeader = false;
          continue;
        }
        if (!t.startsWith('##')) {
          final idx = t.indexOf(':');
          if (idx <= 0) {
            warn('bad-header-line', lineNo, 'Expected "key: value".');
          } else {
            final key = t.substring(0, idx).trim().toLowerCase();
            const known = {'id', 'title', 'aliases', 'fixture'};
            if (!known.contains(key)) {
              warn('unknown-header-key', lineNo, 'Unknown header key "$key".');
            }
            header[key] = t.substring(idx + 1).trim();
          }
          continue;
        }
        inHeader = false;
      }

      if (t.startsWith('#note ') || t == '#note') {
        warn('owner-note', lineNo, t.length > 6 ? t.substring(6).trim() : '');
        continue;
      }

      if (t.startsWith('###')) {
        flush();
        final headingText = t.substring(3).trim();
        final target = current;
        if (target == null) {
          err('text-outside-section', lineNo,
              'Heading appears before any "## section".');
        } else if (headingText.isEmpty) {
          warn('empty-heading', lineNo, 'Empty "###" heading skipped.');
        } else {
          target.rawParagraphs.add({
            'kind': 'heading',
            'page': currentPage,
            'text': headingText,
          });
        }
        continue;
      }

      if (t.startsWith('##')) {
        flush();
        final title = t.substring(2).trim();
        if (title.isEmpty) {
          warn('section-no-title', lineNo, 'Section has no title.');
        }
        current = _SectionBuilder(title, sections.length + 1);
        sections.add(current);
        continue;
      }

      final marker = _pageMarker.firstMatch(t);
      if (marker != null) {
        flush();
        final v = marker.group(1)!;
        currentPage = v == '?' ? null : int.parse(v);
        continue;
      }

      if (t.isEmpty) {
        flush();
        continue;
      }

      if (current == null) {
        err('text-outside-section', lineNo,
            'Text appears before any "## section".');
        continue;
      }
      if (buffer.isEmpty) bufferPage = currentPage;
      buffer.add(line);
    }
    flush();

    var id = header['id'] ?? '';
    if (id.isEmpty) {
      id = 'saint-${order.toString().padLeft(3, '0')}';
      warn('saint-id-generated', null,
          'No "id:" in the header; generated "$id". Add it to the header to '
          'freeze it.');
    }
    final title = header['title'] ?? '';
    if (title.isEmpty) {
      err('missing-field', null, 'Header is missing "title:".');
    }
    final aliases = (header['aliases'] ?? '')
        .split(';')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();

    final slug = id.startsWith('saint-') ? id.substring(6) : id;
    var paragraphNumber = 0;
    final sectionJson = <Map<String, dynamic>>[];
    for (final s in sections) {
      final sectionId = 'sec-$slug-${s.number.toString().padLeft(3, '0')}';
      final occurrences = <String, int>{};
      final paragraphs = <Map<String, dynamic>>[];
      for (final raw in s.rawParagraphs) {
        final pText = raw['text'] as String;
        final occurrence = occurrences[pText] ?? 0;
        occurrences[pText] = occurrence + 1;
        final pId =
            registry.assign(IdRegistry.fingerprint(sectionId, pText, occurrence));
        paragraphNumber++;
        paragraphs.add({
          'id': pId,
          'order': paragraphs.length + 1,
          'kind': raw['kind'],
          'page': raw['page'],
          'text': pText,
        });
      }
      int? pageStart;
      int? pageEnd;
      if (paragraphs.isNotEmpty && paragraphs.every((p) => p['page'] != null)) {
        pageStart = paragraphs.first['page'] as int;
        pageEnd = paragraphs.last['page'] as int;
      }
      sectionJson.add({
        'id': sectionId,
        'title': s.title,
        'order': s.number,
        'pageStart': pageStart,
        'pageEnd': pageEnd,
        'paragraphs': paragraphs,
      });
    }
    if (paragraphNumber == 0) {
      warn('empty-saint', null, 'No paragraphs found in this file.');
    }

    return _ConvertedSaint({
      'schemaVersion': 1,
      'id': id,
      'title': title,
      'order': order,
      'aliases': aliases,
      'sections': sectionJson,
    }, issues);
  }
}
