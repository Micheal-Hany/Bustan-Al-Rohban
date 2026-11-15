import 'dart:convert';

import 'package:bustan_al_rohban/core/content/authoring_converter.dart';
import 'package:bustan_al_rohban/core/content/id_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

const _book = '@book\nid: test-book\ntitle: كتاب\nlanguage: ar\n';

const _saintText = '''@saint
id: saint-demo
title: قديس تجريبي
aliases: اسم أول; اسم ثان

## القسم الأول
[p.1]
الفقرة الأولى.

هَذِهِ فِقْرَةٌ بِالتَّشْكِيلِ.
[p.2]
### عنوان فرعي
الفقرة الثالثة
بسطرين.
#note تحقق من هذه الفقرة

## القسم الثاني
[p.?]
فقرة بلا صفحة.
''';

ConvertedBook convert(
  String saintText, {
  IdRegistry? registry,
  String name = '001-demo.txt',
}) {
  return const AuthoringConverter().convertBook(
    bookText: _book,
    saintTexts: {name: saintText},
    registry: registry ?? IdRegistry(),
  );
}

void main() {
  group('authoring format to JSON', () {
    test('produces the expected structure', () {
      final r = convert(_saintText);
      expect(r.report.isValid, isTrue, reason: '${r.report.errors}');

      final saint = r.saintFiles['saints/saint-demo.json']!;
      expect(saint['id'], 'saint-demo');
      expect(saint['title'], 'قديس تجريبي');
      expect(saint['order'], 1);
      expect(saint['aliases'], ['اسم أول', 'اسم ثان']);

      final sections = saint['sections'] as List<Map<String, dynamic>>;
      expect(sections.map((s) => s['id']),
          ['sec-demo-001', 'sec-demo-002']);
      final paragraphs = sections[0]['paragraphs'] as List;
      expect(paragraphs.length, 4);
      expect((paragraphs[0] as Map)['id'], 'p-000001');
      expect((paragraphs[0] as Map)['page'], 1);
      expect((paragraphs[2] as Map)['kind'], 'heading');
      expect((paragraphs[2] as Map)['page'], 2);
      expect((paragraphs[3] as Map)['text'], 'الفقرة الثالثة\nبسطرين.');
      expect(sections[0]['pageStart'], 1);
      expect(sections[0]['pageEnd'], 2);
    });

    test('original text is byte-identical, including diacritics', () {
      final r = convert(_saintText);
      final saint = r.saintFiles['saints/saint-demo.json']!;
      final p = ((saint['sections'] as List)[0] as Map)['paragraphs'] as List;
      expect((p[1] as Map)['text'], 'هَذِهِ فِقْرَةٌ بِالتَّشْكِيلِ.');
    });

    test('[p.?] gives a null page, never a guessed number', () {
      final r = convert(_saintText);
      final saint = r.saintFiles['saints/saint-demo.json']!;
      final second = (saint['sections'] as List)[1] as Map;
      final para = (second['paragraphs'] as List).single as Map;
      expect(para['page'], isNull);
      expect(second['pageStart'], isNull);
      expect(second['pageEnd'], isNull);
      expect(warningCodes(r.report), contains('page-unknown'));
    });

    test('owner notes become warnings and are not shipped as text', () {
      final r = convert(_saintText);
      final note = r.issues.firstWhere((i) => i.code == 'owner-note');
      expect(note.message, 'تحقق من هذه الفقرة');
      expect(note.line, isNotNull);
      expect(jsonEncode(r.saintFiles), isNot(contains('تحقق من هذه الفقرة')));
    });

    test('handles CRLF line endings and a BOM', () {
      final crlf = '﻿${_saintText.replaceAll('\n', '\r\n')}';
      final a = convert(_saintText);
      final b = convert(crlf);
      expect(jsonEncode(b.saintFiles), jsonEncode(a.saintFiles));
      expect(b.manifest['contentHash'], a.manifest['contentHash']);
    });

    test('manifest has counts, edition and a valid content hash', () {
      final r = convert(_saintText);
      final entry = (r.manifest['saints'] as List).single as Map;
      expect(entry['sectionCount'], 2);
      expect(entry['paragraphCount'], 5);
      expect(entry['file'], 'saints/saint-demo.json');
      expect((r.manifest['contentHash'] as String), startsWith('sha256:'));
      expect(r.manifest['fixture'], false);
    });

    test('text before any section is an error', () {
      final r = convert('@saint\nid: saint-x\ntitle: س\n\nنص بلا قسم\n');
      expect(errorCodes(r.report), contains('text-outside-section'));
    });

    test('missing @saint marker is an error', () {
      final r = convert('## قسم\nنص\n');
      expect(errorCodes(r.report), contains('missing-saint-header'));
    });

    test('generated saint id is reported when the header has none', () {
      final r = convert('@saint\ntitle: س\n\n## قسم\n[p.1]\nنص\n');
      expect(warningCodes(r.report), contains('saint-id-generated'));
      expect(r.saintFiles.keys.single, 'saints/saint-001.json');
    });

    test('saints are ordered by file name', () {
      final r = const AuthoringConverter().convertBook(
        bookText: _book,
        saintTexts: {
          '002-b.txt': '@saint\nid: saint-b\ntitle: ب\n\n## ق\n[p.1]\nنص ب\n',
          '001-a.txt': '@saint\nid: saint-a\ntitle: أ\n\n## ق\n[p.1]\nنص أ\n',
        },
        registry: IdRegistry(),
      );
      final ids = (r.manifest['saints'] as List).map((e) => (e as Map)['id']);
      expect(ids, ['saint-a', 'saint-b']);
    });
  });

  group('stable paragraph ids', () {
    test('re-import keeps ids and the hash', () {
      final registry = IdRegistry();
      final first = convert(_saintText, registry: registry);
      final reloaded = IdRegistry.fromJson(
          jsonDecode(registry.toJsonString()) as Map<String, dynamic>);
      final second = convert(_saintText, registry: reloaded);
      expect(jsonEncode(second.saintFiles), jsonEncode(first.saintFiles));
      expect(second.manifest['contentHash'], first.manifest['contentHash']);
      expect(second.issues.map((i) => i.code),
          isNot(contains('paragraph-retired')));
    });

    test('a new paragraph gets a new id and existing ids do not move', () {
      final registry = IdRegistry();
      convert(_saintText, registry: registry);
      final edited = _saintText.replaceFirst(
        'الفقرة الأولى.\n',
        'فقرة جديدة في البداية.\n\nالفقرة الأولى.\n',
      );
      final r = convert(edited, registry: registry);
      final saint = r.saintFiles['saints/saint-demo.json']!;
      final p = ((saint['sections'] as List)[0] as Map)['paragraphs'] as List;
      expect((p[0] as Map)['text'], 'فقرة جديدة في البداية.');
      expect((p[0] as Map)['id'], 'p-000006');
      expect((p[1] as Map)['id'], 'p-000001');
    });

    test('an edited paragraph is reported as retired', () {
      final registry = IdRegistry();
      convert(_saintText, registry: registry);
      final edited = _saintText.replaceFirst('الفقرة الأولى.', 'الفقرة الأولى!');
      final r = convert(edited, registry: registry);
      final retired = r.issues.where((i) => i.code == 'paragraph-retired');
      expect(retired.length, 1);
      expect(retired.single.message, contains('p-000001'));
    });

    test('identical paragraphs in one section get different ids', () {
      final r = convert('@saint\nid: saint-d\ntitle: د\n\n## ق\n[p.1]\n'
          'نفس النص.\n\nنفس النص.\n');
      final saint = r.saintFiles['saints/saint-d.json']!;
      final p = ((saint['sections'] as List)[0] as Map)['paragraphs'] as List;
      expect((p[0] as Map)['id'], isNot((p[1] as Map)['id']));
      expect(r.report.isValid, isTrue);
    });

    test('registry survives a JSON round trip and never reuses numbers', () {
      final a = IdRegistry();
      final id1 = a.assign('fp1');
      final b = IdRegistry.fromJson(
          jsonDecode(a.toJsonString()) as Map<String, dynamic>);
      expect(b.assign('fp1'), id1);
      expect(b.assign('fp2'), 'p-000002');
    });
  });
}
