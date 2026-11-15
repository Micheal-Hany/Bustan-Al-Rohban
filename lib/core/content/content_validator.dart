import 'dart:convert';

import 'content_hasher.dart';
import 'content_issue.dart';
import 'content_models.dart';

final _slugPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
final _paragraphIdPattern = RegExp(r'^p-\d{6}$');
final _suspiciousPattern = RegExp('[A-Za-z-�]');

/// An ID found while parsing, with where it was found.
class IdRef {
  const IdRef(this.id, this.file, this.path);

  final String id;
  final String file;
  final String path;
}

class ManifestParseResult {
  const ManifestParseResult(this.manifest, this.issues);

  /// `null` when there is at least one error.
  final ContentManifest? manifest;
  final List<ContentIssue> issues;
}

class SaintParseResult {
  const SaintParseResult(this.saint, this.issues, this.ids);

  /// `null` when there is at least one error.
  final Saint? saint;
  final List<ContentIssue> issues;
  final List<IdRef> ids;
}

class BookParseResult {
  const BookParseResult(this.book, this.report);

  /// `null` when the report has errors.
  final ContentBook? book;
  final ValidationReport report;
}

/// Validates content JSON against `docs/CONTENT_SCHEMA.md` (schema version 1).
class ContentValidator {
  const ContentValidator({this.maxParagraphLength = 3000});

  /// Longer paragraphs get a warning (they may need splitting).
  final int maxParagraphLength;

  ManifestParseResult parseManifest(
    String json, {
    String file = 'manifest.json',
  }) {
    final issues = <ContentIssue>[];
    final r = _Reader(file, issues);
    final root = r.decodeObject(json);
    if (root == null) return ManifestParseResult(null, issues);

    final schemaVersion = r.integer(root, 'schemaVersion', '', min: 1);
    if (schemaVersion != null && schemaVersion != 1) {
      r.error('unsupported-schema', 'schemaVersion',
          'Unsupported schemaVersion $schemaVersion (this app reads 1).');
    }
    final contentVersion = r.integer(root, 'contentVersion', '', min: 1);
    final bookId = r.string(root, 'bookId', '');
    final title = r.string(root, 'title', '');
    final language = r.string(root, 'language', '');
    final contentHash = r.string(root, 'contentHash', '');
    final fixture = r.boolOrDefault(root, 'fixture', '');

    final edition = <String, String>{};
    final rawEdition = root['edition'];
    if (rawEdition is Map) {
      rawEdition.forEach((k, v) => edition[k.toString()] = v.toString());
    } else if (rawEdition != null) {
      r.error('wrong-type', 'edition', 'Field "edition" must be an object.');
    }

    final entries = <SaintEntry>[];
    final orders = <int?>[];
    final seenIds = <String>{};
    final rawSaints = r.list(root, 'saints', '');
    if (rawSaints != null) {
      for (var i = 0; i < rawSaints.length; i++) {
        final path = 'saints[$i]';
        final m = r.asObject(rawSaints[i], path);
        if (m == null) {
          orders.add(null);
          continue;
        }
        final id = r.slug(m, 'id', path);
        final sTitle = r.string(m, 'title', path);
        final order = r.integer(m, 'order', path, min: 1);
        final fileName = r.string(m, 'file', path);
        final sectionCount = r.integer(m, 'sectionCount', path);
        final paragraphCount = r.integer(m, 'paragraphCount', path);
        final aliases = r.stringList(m, 'aliases', path);
        orders.add(order);
        if (id != null && !seenIds.add(id)) {
          r.error('duplicate-id', '$path.id',
              'Duplicate saint id "$id" in the manifest.');
        }
        if (id != null &&
            sTitle != null &&
            order != null &&
            fileName != null &&
            sectionCount != null &&
            paragraphCount != null) {
          entries.add(SaintEntry(
            id: id,
            title: sTitle,
            order: order,
            aliases: aliases ?? const [],
            file: fileName,
            sectionCount: sectionCount,
            paragraphCount: paragraphCount,
          ));
        }
      }
      r.checkOrders(orders, 'saints');
    }

    if (issues.any((i) => i.isError) ||
        schemaVersion == null ||
        contentVersion == null ||
        bookId == null ||
        title == null ||
        language == null ||
        contentHash == null) {
      return ManifestParseResult(null, issues);
    }
    return ManifestParseResult(
      ContentManifest(
        schemaVersion: schemaVersion,
        contentVersion: contentVersion,
        bookId: bookId,
        title: title,
        language: language,
        fixture: fixture,
        edition: edition,
        saints: entries,
        contentHash: contentHash,
      ),
      issues,
    );
  }

  SaintParseResult parseSaint(String json, {required String file}) {
    final issues = <ContentIssue>[];
    final ids = <IdRef>[];
    final r = _Reader(file, issues);
    final root = r.decodeObject(json);
    if (root == null) return SaintParseResult(null, issues, ids);

    final schemaVersion = r.integer(root, 'schemaVersion', '', min: 1);
    if (schemaVersion != null && schemaVersion != 1) {
      r.error('unsupported-schema', 'schemaVersion',
          'Unsupported schemaVersion $schemaVersion (this app reads 1).');
    }
    final id = r.slug(root, 'id', '');
    final title = r.string(root, 'title', '');
    final order = r.integer(root, 'order', '', min: 1);
    final aliases = r.stringList(root, 'aliases', '');
    if (id != null) ids.add(IdRef(id, file, 'id'));
    if (aliases == null || aliases.isEmpty) {
      r.warning('saint-no-aliases', 'aliases',
          'Saint has no aliases; scoped chat and search may miss name variants.');
    }

    final sections = <Section>[];
    final sectionOrders = <int?>[];
    int? lastPage;
    final rawSections = r.list(root, 'sections', '');
    if (rawSections != null) {
      for (var si = 0; si < rawSections.length; si++) {
        final sPath = 'sections[$si]';
        final sm = r.asObject(rawSections[si], sPath);
        if (sm == null) {
          sectionOrders.add(null);
          continue;
        }
        final sId = r.slug(sm, 'id', sPath);
        final sTitle = r.string(sm, 'title', sPath);
        final sOrder = r.integer(sm, 'order', sPath, min: 1);
        sectionOrders.add(sOrder);
        if (sId != null) ids.add(IdRef(sId, file, '$sPath.id'));

        final paragraphs = <Paragraph>[];
        final pOrders = <int?>[];
        final rawParagraphs = r.list(sm, 'paragraphs', sPath);
        if (rawParagraphs != null) {
          if (rawParagraphs.isEmpty) {
            r.warning('empty-section', '$sPath.paragraphs',
                'Section has no paragraphs.');
          }
          for (var pi = 0; pi < rawParagraphs.length; pi++) {
            final pPath = '$sPath.paragraphs[$pi]';
            final pm = r.asObject(rawParagraphs[pi], pPath);
            if (pm == null) {
              pOrders.add(null);
              continue;
            }
            final pId = r.string(pm, 'id', pPath);
            if (pId != null) {
              ids.add(IdRef(pId, file, '$pPath.id'));
              if (!_paragraphIdPattern.hasMatch(pId)) {
                r.error('bad-id', '$pPath.id',
                    'Paragraph id "$pId" must look like p-000001.');
              }
            }
            final pOrder = r.integer(pm, 'order', pPath, min: 1);
            pOrders.add(pOrder);
            final text = r.string(pm, 'text', pPath);

            var kind = ParagraphKind.body;
            final rawKind = pm['kind'];
            if (rawKind != null) {
              if (rawKind == 'body') {
                kind = ParagraphKind.body;
              } else if (rawKind == 'heading') {
                kind = ParagraphKind.heading;
              } else {
                r.error('bad-kind', '$pPath.kind',
                    'Field "kind" must be "body" or "heading".');
              }
            }

            int? page;
            if (!pm.containsKey('page')) {
              r.error('missing-field', '$pPath.page',
                  'Missing field "page" (use null when the page is unknown).');
            } else if (pm['page'] != null) {
              final v = pm['page'];
              if (v is! int || v < 1) {
                r.error('bad-page', '$pPath.page',
                    'Field "page" must be a positive integer or null.');
              } else {
                page = v;
                if (lastPage != null && v < lastPage) {
                  r.error('page-decreasing', '$pPath.page',
                      'Page $v comes after page $lastPage; pages must not '
                      'decrease within a saint.');
                }
                lastPage = v;
              }
            } else {
              r.warning('page-unknown', '$pPath.page',
                  'Paragraph has no page number (null).');
            }

            if (text != null) {
              if (text.length > maxParagraphLength) {
                r.warning('long-paragraph', '$pPath.text',
                    'Paragraph has ${text.length} characters; consider '
                    'splitting it.');
              }
              if (_suspiciousPattern.hasMatch(text)) {
                r.warning('suspicious-characters', '$pPath.text',
                    'Contains Latin letters, private-use or replacement '
                    'characters; check the extraction.');
              }
            }

            if (pId != null && pOrder != null && text != null) {
              paragraphs.add(Paragraph(
                id: pId,
                order: pOrder,
                kind: kind,
                page: page,
                text: text,
              ));
            }
          }
          r.checkOrders(pOrders, '$sPath.paragraphs');
        }

        // Derived page range: null when any page in the section is unknown.
        int? expectedStart;
        int? expectedEnd;
        if (paragraphs.isNotEmpty && paragraphs.every((p) => p.page != null)) {
          expectedStart = paragraphs.first.page;
          expectedEnd = paragraphs.last.page;
        }
        final gotStart = _optionalPage(r, sm, 'pageStart', sPath);
        final gotEnd = _optionalPage(r, sm, 'pageEnd', sPath);
        if (paragraphs.length == (rawParagraphs?.length ?? -1) &&
            (gotStart != expectedStart || gotEnd != expectedEnd)) {
          r.error('page-range-mismatch', sPath,
              'pageStart/pageEnd ($gotStart/$gotEnd) do not match the '
              'paragraph pages ($expectedStart/$expectedEnd).');
        }

        if (sId != null && sTitle != null && sOrder != null) {
          sections.add(Section(
            id: sId,
            title: sTitle,
            order: sOrder,
            pageStart: expectedStart,
            pageEnd: expectedEnd,
            paragraphs: paragraphs,
          ));
        }
      }
      r.checkOrders(sectionOrders, 'sections');
    }

    if (issues.any((i) => i.isError) ||
        id == null ||
        title == null ||
        order == null) {
      return SaintParseResult(null, issues, ids);
    }
    return SaintParseResult(
      Saint(
        id: id,
        title: title,
        order: order,
        aliases: aliases ?? const [],
        sections: sections,
      ),
      issues,
      ids,
    );
  }

  /// Duplicate-ID errors for every ID defined more than once in [refs].
  List<ContentIssue> duplicateIssues(Iterable<IdRef> refs) {
    final first = <String, IdRef>{};
    final issues = <ContentIssue>[];
    for (final ref in refs) {
      final prior = first[ref.id];
      if (prior == null) {
        first[ref.id] = ref;
      } else {
        issues.add(ContentIssue(
          severity: IssueSeverity.error,
          code: 'duplicate-id',
          file: ref.file,
          path: ref.path,
          message: 'Duplicate id "${ref.id}" '
              '(first defined in ${prior.file} at ${prior.path}).',
        ));
      }
    }
    return issues;
  }

  /// Validates the whole book: manifest, every saint file, cross-file rules,
  /// and the content hash.
  BookParseResult validateBook({
    required String manifestJson,
    required Map<String, String> saintJsonByFile,
    bool allowFixture = true,
  }) {
    final issues = <ContentIssue>[];
    final mp = parseManifest(manifestJson);
    issues.addAll(mp.issues);
    final manifest = mp.manifest;
    if (manifest == null) {
      return BookParseResult(null, ValidationReport(issues));
    }

    if (manifest.fixture && !allowFixture) {
      issues.add(const ContentIssue(
        severity: IssueSeverity.error,
        code: 'fixture-in-release',
        file: 'manifest.json',
        path: 'fixture',
        message: 'FAKE fixture content must not be included in a release build.',
      ));
    }

    final saints = <Saint>[];
    final refs = <IdRef>[];
    for (var i = 0; i < manifest.saints.length; i++) {
      final entry = manifest.saints[i];
      final text = saintJsonByFile[entry.file];
      if (text == null) {
        issues.add(ContentIssue(
          severity: IssueSeverity.error,
          code: 'missing-file',
          file: 'manifest.json',
          path: 'saints[$i].file',
          message: 'Saint file "${entry.file}" listed in the manifest was not '
              'found.',
        ));
        continue;
      }
      final sp = parseSaint(text, file: entry.file);
      issues.addAll(sp.issues);
      refs.addAll(sp.ids);
      final saint = sp.saint;
      if (saint == null) continue;
      issues.addAll(_crossCheck(entry, saint));
      saints.add(saint);
    }
    issues.addAll(duplicateIssues(refs));

    final hasErrors = issues.any((i) => i.isError);
    if (!hasErrors) {
      final actual = ContentHasher.hash(saints);
      if (actual != manifest.contentHash) {
        issues.add(ContentIssue(
          severity: IssueSeverity.error,
          code: 'content-hash-mismatch',
          file: 'manifest.json',
          path: 'contentHash',
          message: 'contentHash is ${manifest.contentHash} but the saint files '
              'hash to $actual.',
        ));
      }
    }

    final report = ValidationReport(issues);
    if (!report.isValid) return BookParseResult(null, report);
    return BookParseResult(
      ContentBook(manifest: manifest, saints: saints),
      report,
    );
  }

  List<ContentIssue> _crossCheck(SaintEntry entry, Saint saint) {
    final issues = <ContentIssue>[];
    void err(String code, String message) => issues.add(ContentIssue(
          severity: IssueSeverity.error,
          code: code,
          file: entry.file,
          message: message,
        ));
    if (saint.id != entry.id) {
      err('id-mismatch',
          'File id "${saint.id}" differs from the manifest id "${entry.id}".');
    }
    if (saint.order != entry.order) {
      err('order-mismatch',
          'File order ${saint.order} differs from the manifest order '
          '${entry.order}.');
    }
    if (saint.sections.length != entry.sectionCount) {
      err('count-mismatch',
          'Manifest says ${entry.sectionCount} sections, file has '
          '${saint.sections.length}.');
    }
    if (saint.paragraphCount != entry.paragraphCount) {
      err('count-mismatch',
          'Manifest says ${entry.paragraphCount} paragraphs, file has '
          '${saint.paragraphCount}.');
    }
    return issues;
  }

  int? _optionalPage(
      _Reader r, Map<String, dynamic> m, String key, String path) {
    final v = m[key];
    if (v == null) return null;
    if (v is! int || v < 1) {
      r.error('bad-page', '$path.$key',
          'Field "$key" must be a positive integer or null.');
      return null;
    }
    return v;
  }
}

class _Reader {
  _Reader(this.file, this.issues);

  final String file;
  final List<ContentIssue> issues;

  void error(String code, String path, String message) =>
      issues.add(ContentIssue(
        severity: IssueSeverity.error,
        code: code,
        file: file,
        path: path,
        message: message,
      ));

  void warning(String code, String path, String message) =>
      issues.add(ContentIssue(
        severity: IssueSeverity.warning,
        code: code,
        file: file,
        path: path,
        message: message,
      ));

  String _join(String path, String key) => path.isEmpty ? key : '$path.$key';

  Map<String, dynamic>? decodeObject(String json) {
    Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException catch (e) {
      error('malformed-json', '', 'File is not valid JSON: ${e.message}');
      return null;
    }
    if (decoded is! Map) {
      error('wrong-type', '', 'The top level of the file must be an object.');
      return null;
    }
    return Map<String, dynamic>.from(decoded);
  }

  Map<String, dynamic>? asObject(Object? value, String path) {
    if (value is Map) return Map<String, dynamic>.from(value);
    error('wrong-type', path, 'Expected an object here.');
    return null;
  }

  String? string(Map<String, dynamic> m, String key, String path) {
    final p = _join(path, key);
    if (!m.containsKey(key) || m[key] == null) {
      error('missing-field', p, 'Missing required field "$key".');
      return null;
    }
    final v = m[key];
    if (v is! String) {
      error('wrong-type', p, 'Field "$key" must be a string.');
      return null;
    }
    if (v.trim().isEmpty) {
      error('empty-field', p, 'Field "$key" must not be empty.');
      return null;
    }
    return v;
  }

  String? slug(Map<String, dynamic> m, String key, String path) {
    final v = string(m, key, path);
    if (v != null && !_slugPattern.hasMatch(v)) {
      error('bad-id', _join(path, key),
          'Id "$v" must be lowercase letters, digits and hyphens.');
    }
    return v;
  }

  int? integer(Map<String, dynamic> m, String key, String path,
      {int min = 0}) {
    final p = _join(path, key);
    if (!m.containsKey(key) || m[key] == null) {
      error('missing-field', p, 'Missing required field "$key".');
      return null;
    }
    final v = m[key];
    if (v is! int) {
      error('wrong-type', p, 'Field "$key" must be an integer.');
      return null;
    }
    if (v < min) {
      error('out-of-range', p, 'Field "$key" must be at least $min.');
      return null;
    }
    return v;
  }

  bool boolOrDefault(Map<String, dynamic> m, String key, String path) {
    final v = m[key];
    if (v == null) return false;
    if (v is bool) return v;
    error('wrong-type', _join(path, key), 'Field "$key" must be true or false.');
    return false;
  }

  List<dynamic>? list(Map<String, dynamic> m, String key, String path) {
    final p = _join(path, key);
    if (!m.containsKey(key) || m[key] == null) {
      error('missing-field', p, 'Missing required field "$key".');
      return null;
    }
    final v = m[key];
    if (v is! List) {
      error('wrong-type', p, 'Field "$key" must be a list.');
      return null;
    }
    return v;
  }

  /// Optional list of strings; `null` when absent.
  List<String>? stringList(Map<String, dynamic> m, String key, String path) {
    final v = m[key];
    if (v == null) return null;
    if (v is! List || v.any((e) => e is! String)) {
      error('wrong-type', _join(path, key),
          'Field "$key" must be a list of strings.');
      return null;
    }
    return v.cast<String>();
  }

  /// Reports the first item whose `order` is not its 1-based position.
  void checkOrders(List<int?> orders, String parentPath) {
    for (var i = 0; i < orders.length; i++) {
      final o = orders[i];
      if (o != null && o != i + 1) {
        error('order-gap', '$parentPath[$i].order',
            'Expected order ${i + 1} (contiguous from 1) but found $o.');
        return;
      }
    }
  }
}
