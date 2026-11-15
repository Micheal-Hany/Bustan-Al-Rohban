import 'dart:convert';
import 'dart:io';

import 'package:bustan_al_rohban/core/content/authoring_converter.dart';
import 'package:bustan_al_rohban/core/content/content_issue.dart';
import 'package:bustan_al_rohban/core/content/content_loader.dart';
import 'package:bustan_al_rohban/core/content/id_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

void main() {
  group('shipped FAKE fixture (assets/content)', () {
    final source = DiskContentSource('assets/content');

    test('loads, validates, and is clearly labeled FAKE', () async {
      final loaded = await ContentLoader(source).loadBook();
      final book = loaded.book;
      expect(book.manifest.fixture, isTrue);
      expect(book.saints.length, 3);
      for (final saint in book.saints) {
        expect(saint.title, startsWith('[تجريبي]'));
        expect(saint.sections.length, inInclusiveRange(2, 3));
        for (final section in saint.sections) {
          expect(section.title, startsWith('[تجريبي]'));
          expect(section.paragraphs, isNotEmpty);
        }
      }
    });

    test('order is stable and ids are unique', () async {
      final book = (await ContentLoader(source).loadBook()).book;
      expect(book.saints.map((s) => s.id),
          ['saint-fake-one', 'saint-fake-two', 'saint-fake-three']);
      final ids = <String>{};
      for (final s in book.saints) {
        for (final sec in s.sections) {
          for (final p in sec.paragraphs) {
            expect(ids.add(p.id), isTrue, reason: 'duplicate ${p.id}');
          }
        }
      }
    });

    test('release mode refuses the FAKE fixture', () async {
      expect(
        () => ContentLoader(source).loadBook(allowFixture: false),
        throwsA(isA<ContentValidationException>()),
      );
    });

    test('has an unknown page, a heading, and a diacritics paragraph',
        () async {
      final book = (await ContentLoader(source).loadBook()).book;
      final all = [
        for (final s in book.saints)
          for (final sec in s.sections) ...sec.paragraphs,
      ];
      expect(all.any((p) => p.page == null), isTrue);
      expect(all.any((p) => p.kind.name == 'heading'), isTrue);
      expect(all.any((p) => p.text.contains('َ')), isTrue);
    });
  });

  group('authoring sources match the shipped JSON', () {
    test('content_src/fake converts to exactly the committed assets', () {
      final dir = Directory('content_src/fake');
      final saintTexts = <String, String>{};
      for (final f in dir.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (name.endsWith('.txt') && name != 'book.txt') {
          saintTexts[name] = f.readAsStringSync();
        }
      }
      final registry = IdRegistry.fromJson(jsonDecode(
              File('content_src/fake/id-registry.json').readAsStringSync())
          as Map<String, dynamic>);

      final result = const AuthoringConverter().convertBook(
        bookText: File('content_src/fake/book.txt').readAsStringSync(),
        saintTexts: saintTexts,
        registry: registry,
      );
      expect(result.report.errors, isEmpty, reason: '${result.report.errors}');
      expect(result.report.warnings.map((w) => w.code),
          isNot(contains('paragraph-retired')));

      final shippedManifest = jsonDecode(
              File('assets/content/manifest.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(jsonDecode(jsonEncode(result.manifest)), shippedManifest);

      for (final entry in result.saintFiles.entries) {
        final shipped =
            jsonDecode(File('assets/content/${entry.key}').readAsStringSync());
        expect(jsonDecode(jsonEncode(entry.value)), shipped,
            reason: entry.key);
      }
    });
  });

  group('invalid fixture (assets/content_fixtures/invalid)', () {
    test('fails with understandable errors', () async {
      final loader =
          ContentLoader(DiskContentSource('assets/content_fixtures/invalid'));
      try {
        await loader.loadBook();
        fail('expected ContentValidationException');
      } on ContentValidationException catch (e) {
        final codes = e.report.errors.map((i) => i.code).toList();
        expect(codes, contains('duplicate-id'));
        expect(codes, contains('empty-field'));
        expect(e.toString(), contains('saints/saint-bad.json'));
      }
    });
  });
}
