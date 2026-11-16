import 'package:bustan_al_rohban/core/content/content_issue.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/content/test_support.dart';
import '../library/library_test_support.dart';
import 'search_test_support.dart';

void main() {
  group('SearchRepository', () {
    test('finds paragraphs and returns titles and original snippets',
        () async {
      final repo = searchRepoFor(probeFor(searchBook()));
      final r = await repo.search('رحمة');
      expect(r.total, 2);
      final byId = {for (final v in r.results) v.paragraph.paragraphId: v};
      final body = byId['p-000001']!;
      expect(body.saintTitle, 'القديس الأول');
      expect(body.sectionTitle, 'القسم الأول');
      // The snippet is the ORIGINAL text, diacritics intact.
      expect(body.snippet.text, vowelledText);
    });

    test('vowelled and plain queries give identical results', () async {
      final repo = searchRepoFor(probeFor(searchBook()));
      final a = await repo.search('رَحْمَة');
      final b = await repo.search('رحمه');
      expect(a.results.map((r) => r.paragraph.paragraphId),
          b.results.map((r) => r.paragraph.paragraphId));
    });

    test('alef spellings find أبونا and إبونا', () async {
      final repo = searchRepoFor(probeFor(searchBook()));
      for (final q in ['ابونا', 'أبونا', 'إبونا']) {
        final r = await repo.search(q);
        expect(r.results.map((v) => v.paragraph.paragraphId).toSet(),
            {'p-000002', 'p-000006'},
            reason: q);
      }
    });

    test('result carries the source location', () async {
      final repo = searchRepoFor(probeFor(searchBook()));
      final r = await repo.search('قال الرب');
      final p = r.results.single.paragraph;
      expect(p.saintId, 'saint-a');
      expect(p.sectionId, 'sec-a-002');
      expect(p.paragraphId, 'p-000004');
      expect(p.page, 3);
    });

    test('unknown page stays null in the result', () async {
      final repo = searchRepoFor(probeFor(searchBook()));
      final r = await repo.search('انقطاع');
      expect(r.results.single.paragraph.page, isNull);
    });

    test('no match gives total 0', () async {
      final repo = searchRepoFor(probeFor(searchBook()));
      final r = await repo.search('غير موجود');
      expect(r.total, 0);
      expect(r.results, isEmpty);
    });

    test('the index is built once, reading each file once', () async {
      final source = probeFor(searchBook());
      final repo = searchRepoFor(source);
      expect(repo.isBuilt, isFalse);
      await Future.wait([repo.search('محبة'), repo.search('رحمة')]);
      await repo.search('الرب');
      expect(repo.isBuilt, isTrue);
      expect(source.reads['manifest.json'], 1);
      expect(source.reads['saints/saint-a.json'], 1);
      expect(source.reads['saints/saint-b.json'], 1);
    });

    test('a failed build is not cached; retry succeeds', () async {
      final source = probeFor(searchBook());
      final mem = source.inner as InMemoryContentSource;
      final good = mem.files['saints/saint-b.json']!;
      mem.files['saints/saint-b.json'] = '{ broken';
      final repo = searchRepoFor(source);
      await expectLater(
        repo.search('محبة'),
        throwsA(isA<ContentValidationException>()),
      );
      expect(repo.isBuilt, isFalse);
      mem.files['saints/saint-b.json'] = good;
      final r = await repo.search('محبة');
      expect(r.total, 1);
    });

    test('works with no network access (everything is local)', () async {
      // The source is in memory; this documents that no network is involved.
      final repo = searchRepoFor(probeFor(searchBook()));
      expect((await repo.search('الله')).total, greaterThan(0));
    });
  });
}
