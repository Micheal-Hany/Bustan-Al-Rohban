import 'dart:convert';

import 'package:bustan_al_rohban/core/content/content_issue.dart';
import 'package:bustan_al_rohban/core/content/content_models.dart';
import 'package:bustan_al_rohban/core/content/content_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

void main() {
  const validator = ContentValidator();

  BookParseResult validate(TestBook b, {bool allowFixture = true}) =>
      validator.validateBook(
        manifestJson: b.manifestJson,
        saintJsonByFile: b.files,
        allowFixture: allowFixture,
      );

  group('valid content', () {
    test('loads and preserves order, ids and original text', () {
      final b = buildBook([
        saintJson(id: 'saint-a', sections: [
          sectionJson(id: 'sec-a-001', order: 1, paragraphs: [
            paraJson(id: 'p-000001', order: 1, page: 1, text: 'أَوَّلُ نَصٍّ'),
            paraJson(
                id: 'p-000002',
                order: 2,
                page: 2,
                kind: 'heading',
                text: 'عنوان فرعي'),
          ]),
          sectionJson(
              id: 'sec-a-002',
              order: 2,
              paragraphs: [paraJson(id: 'p-000003', page: 3)]),
        ]),
        saintJson(id: 'saint-b', order: 2, sections: [
          sectionJson(
              id: 'sec-b-001',
              paragraphs: [paraJson(id: 'p-000004', page: 1)]),
        ]),
      ]);
      final result = validate(b);
      expect(result.report.isValid, isTrue, reason: '${result.report.errors}');
      final book = result.book!;
      expect(book.saints.map((s) => s.id), ['saint-a', 'saint-b']);
      final first = book.saints.first.sections.first;
      expect(first.paragraphs.map((p) => p.id), ['p-000001', 'p-000002']);
      expect(first.paragraphs.first.text, 'أَوَّلُ نَصٍّ');
      expect(first.paragraphs.last.kind, ParagraphKind.heading);
      expect(first.pageStart, 1);
      expect(first.pageEnd, 2);
    });
  });

  group('errors', () {
    test('malformed JSON gives an understandable message', () {
      final r = validator.parseSaint('{ not json', file: 'saints/x.json');
      expect(r.saint, isNull);
      expect(r.issues.single.code, 'malformed-json');
      expect(r.issues.single.message, contains('not valid JSON'));
      expect(r.issues.single.file, 'saints/x.json');
    });

    test('top level must be an object', () {
      final r = validator.parseManifest('[1,2]');
      expect(r.manifest, isNull);
      expect(r.issues.single.code, 'wrong-type');
    });

    test('duplicate paragraph ids across saints are rejected', () {
      final b = buildBook([
        saintJson(id: 'saint-a'),
        saintJson(id: 'saint-b', order: 2, sections: [
          sectionJson(id: 'sec-b-001'),
        ]),
      ]);
      final r = validate(b);
      expect(r.book, isNull);
      expect(errorCodes(r.report), contains('duplicate-id'));
      final dup = r.report.errors.firstWhere((e) => e.code == 'duplicate-id');
      expect(dup.message, contains('p-000001'));
      expect(dup.message, contains('first defined'));
    });

    test('duplicate section ids are rejected', () {
      final b = buildBook([
        saintJson(sections: [
          sectionJson(
              id: 'sec-a-001', paragraphs: [paraJson(id: 'p-000001')]),
          sectionJson(
              id: 'sec-a-001',
              order: 2,
              paragraphs: [paraJson(id: 'p-000002')]),
        ]),
      ]);
      expect(errorCodes(validate(b).report), contains('duplicate-id'));
    });

    test('duplicate saint ids in the manifest are rejected', () {
      final b = buildBook([saintJson(), saintJson(order: 2)]);
      final r = validator.parseManifest(b.manifestJson);
      expect(r.manifest, isNull);
      expect(r.issues.map((i) => i.code), contains('duplicate-id'));
    });

    test('missing required fields are reported with their path', () {
      final s = saintJson();
      (s['sections'] as List<Map<String, dynamic>>)[0]['paragraphs'] = [
        {'id': 'p-000001', 'order': 1, 'page': 1},
      ];
      final r = validator.parseSaint(jsonEncode(s), file: 'f.json');
      expect(r.saint, isNull);
      final missing = r.issues.firstWhere((i) => i.code == 'missing-field');
      expect(missing.path, 'sections[0].paragraphs[0].text');
    });

    test('missing title is an error', () {
      final s = saintJson()..remove('title');
      final r = validator.parseSaint(jsonEncode(s), file: 'f.json');
      expect(r.issues.map((i) => i.code), contains('missing-field'));
    });

    test('empty paragraph text is rejected', () {
      final s = saintJson(sections: [
        sectionJson(paragraphs: [paraJson(text: '   ')]),
      ]);
      final r = validator.parseSaint(jsonEncode(s), file: 'f.json');
      expect(r.issues.map((i) => i.code), contains('empty-field'));
    });

    test('order gaps are rejected', () {
      final s = saintJson(sections: [
        sectionJson(paragraphs: [
          paraJson(id: 'p-000001', order: 1),
          paraJson(id: 'p-000002', order: 3),
        ]),
      ]);
      final r = validator.parseSaint(jsonEncode(s), file: 'f.json');
      final gap = r.issues.firstWhere((i) => i.code == 'order-gap');
      expect(gap.message, contains('Expected order 2'));
    });

    test('bad id formats are rejected', () {
      final s = saintJson(sections: [
        sectionJson(paragraphs: [paraJson(id: 'para-1')]),
      ]);
      final r = validator.parseSaint(jsonEncode(s), file: 'f.json');
      expect(r.issues.map((i) => i.code), contains('bad-id'));
      final s2 = saintJson(id: 'Saint A');
      final r2 = validator.parseSaint(jsonEncode(s2), file: 'f.json');
      expect(r2.issues.map((i) => i.code), contains('bad-id'));
    });

    test('invalid page values are rejected', () {
      for (final bad in [0, -3, 'x', 1.5]) {
        final s = saintJson(sections: [
          sectionJson(paragraphs: [paraJson(page: bad)]),
        ]);
        // sectionJson cannot derive a range from a bad page; that is fine.
        final r = validator.parseSaint(jsonEncode(s), file: 'f.json');
        expect(r.issues.map((i) => i.code), contains('bad-page'),
            reason: 'page=$bad');
      }
    });

    test('missing page key is an error (null must be explicit)', () {
      final s = saintJson();
      final p = ((s['sections'] as List)[0] as Map)['paragraphs'] as List;
      (p[0] as Map).remove('page');
      final r = validator.parseSaint(jsonEncode(s), file: 'f.json');
      expect(r.issues.map((i) => i.code), contains('missing-field'));
    });

    test('decreasing pages are rejected', () {
      final s = saintJson(sections: [
        sectionJson(paragraphs: [
          paraJson(id: 'p-000001', order: 1, page: 5),
          paraJson(id: 'p-000002', order: 2, page: 4),
        ]),
      ]);
      final r = validator.parseSaint(jsonEncode(s), file: 'f.json');
      expect(r.issues.map((i) => i.code), contains('page-decreasing'));
    });

    test('section page range must match its paragraphs', () {
      final s = saintJson();
      ((s['sections'] as List)[0] as Map)['pageEnd'] = 99;
      final r = validator.parseSaint(jsonEncode(s), file: 'f.json');
      expect(r.issues.map((i) => i.code), contains('page-range-mismatch'));
    });

    test('unknown schema version is rejected', () {
      final s = saintJson()..['schemaVersion'] = 2;
      final r = validator.parseSaint(jsonEncode(s), file: 'f.json');
      expect(r.issues.map((i) => i.code), contains('unsupported-schema'));
    });

    test('manifest pointing at a missing file is rejected', () {
      final b = buildBook([saintJson()]);
      final r = validator.validateBook(
        manifestJson: b.manifestJson,
        saintJsonByFile: const {},
      );
      expect(errorCodes(r.report), contains('missing-file'));
    });

    test('manifest counts must match the files', () {
      final b = buildBook([saintJson()], sectionCountOverride: 5);
      final r = validate(b);
      expect(errorCodes(r.report), contains('count-mismatch'));
    });

    test('contentHash mismatch is rejected', () {
      final b = buildBook([saintJson()], hashOverride: 'sha256:abc');
      final r = validate(b);
      expect(errorCodes(r.report), contains('content-hash-mismatch'));
    });

    test('hash changes when the text changes', () {
      final a = validate(buildBook([saintJson()])).book!;
      final b = validate(buildBook([
        saintJson(sections: [
          sectionJson(paragraphs: [paraJson(text: 'نص مختلف')]),
        ]),
      ])).book!;
      expect(a.manifest.contentHash, isNot(b.manifest.contentHash));
    });

    test('fixture content is rejected when fixtures are not allowed', () {
      final b = buildBook([saintJson()], fixture: true);
      expect(validate(b).report.isValid, isTrue);
      final r = validate(b, allowFixture: false);
      expect(errorCodes(r.report), contains('fixture-in-release'));
    });
  });

  group('warnings', () {
    test('unknown page, long paragraph, suspicious characters, no aliases', () {
      final s = saintJson(aliases: const [], sections: [
        sectionJson(paragraphs: [
          paraJson(id: 'p-000001', order: 1, page: null),
          paraJson(id: 'p-000002', order: 2, page: null, text: 'ا' * 3001),
          paraJson(id: 'p-000003', order: 3, page: null, text: 'نص abc نص'),
        ]),
      ]);
      final r = validator.parseSaint(jsonEncode(s), file: 'f.json');
      expect(r.saint, isNotNull, reason: 'warnings must not block loading');
      final codes = r.issues.map((i) => i.code).toList();
      expect(codes, contains('page-unknown'));
      expect(codes, contains('long-paragraph'));
      expect(codes, contains('suspicious-characters'));
      expect(codes, contains('saint-no-aliases'));
      expect(r.issues.every((i) => i.severity == IssueSeverity.warning),
          isTrue);
    });

    test('null page keeps the section page range null', () {
      final s = saintJson(sections: [
        sectionJson(paragraphs: [
          paraJson(id: 'p-000001', order: 1, page: 1),
          paraJson(id: 'p-000002', order: 2, page: null),
        ]),
      ]);
      final r = validator.parseSaint(jsonEncode(s), file: 'f.json');
      final section = r.saint!.sections.single;
      expect(section.pageStart, isNull);
      expect(section.pageEnd, isNull);
    });
  });

  group('report', () {
    test('markdown report lists errors and warnings', () {
      final b = buildBook([saintJson()], hashOverride: 'sha256:abc');
      final md = validate(b).report.toMarkdown();
      expect(md, contains('## Errors'));
      expect(md, contains('content-hash-mismatch'));
      expect(md, contains('## Warnings'));
    });
  });
}
