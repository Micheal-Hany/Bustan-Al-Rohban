import 'package:bustan_al_rohban/app/strings.dart';
import 'package:bustan_al_rohban/features/library/presentation/load_status.dart';
import 'package:bustan_al_rohban/features/reader/domain/editorial.dart';
import 'package:bustan_al_rohban/features/reader/domain/reader_items.dart';
import 'package:bustan_al_rohban/features/reader/presentation/reader_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/content/test_support.dart';
import '../library/library_test_support.dart';

ReaderCubit _cubit(
  ProbeSource source, {
  String saintId = 'saint-a',
  String sectionId = 'sec-a-001',
  String? paragraphId,
  EditorialSource? editorial,
}) =>
    ReaderCubit(
      repoFor(source),
      saintId: saintId,
      sectionId: sectionId,
      paragraphId: paragraphId,
      editorial: editorial,
    );

void main() {
  group('ReaderCubit', () {
    test('loads a section into items', () async {
      final c = _cubit(probeFor(twoSaintBook()));
      expect(c.state.status, LoadStatus.loading);
      await c.load();
      expect(c.state.status, LoadStatus.loaded);
      expect(c.state.section!.id, 'sec-a-001');
      expect(c.state.items.first, isA<HeaderItem>());
      expect(c.state.items.whereType<ParagraphItem>().length, 2);
      expect(c.state.initialIndex, 0);
      await c.close();
    });

    test('opens at a paragraph anchor', () async {
      final c = _cubit(probeFor(twoSaintBook()), paragraphId: 'p-000002');
      await c.load();
      expect(c.state.items[c.state.initialIndex].paragraphId, 'p-000002');
      await c.close();
    });

    test('an unknown anchor opens at the top', () async {
      final c = _cubit(probeFor(twoSaintBook()), paragraphId: 'p-999999');
      await c.load();
      expect(c.state.status, LoadStatus.loaded);
      expect(c.state.initialIndex, 0);
      await c.close();
    });

    test('unknown section gives the not-found empty state', () async {
      final c = _cubit(probeFor(twoSaintBook()), sectionId: 'sec-zzz');
      await c.load();
      expect(c.state.status, LoadStatus.empty);
      expect(c.state.message, AppStrings.notFound);
      await c.close();
    });

    test('unknown saint gives an error', () async {
      final c = _cubit(probeFor(twoSaintBook()), saintId: 'saint-zzz');
      await c.load();
      expect(c.state.status, LoadStatus.error);
      await c.close();
    });

    test('a section without paragraphs gives an empty state', () async {
      final book = buildBook([
        saintJson(sections: [sectionJson(paragraphs: [])]),
      ]);
      final c = _cubit(probeFor(book));
      await c.load();
      expect(c.state.status, LoadStatus.empty);
      expect(c.state.message, AppStrings.emptyParagraphs);
      await c.close();
    });

    test('fixture books get the FAKE editorial sample', () async {
      final book = buildBook([saintJson()], fixture: true);
      final c = _cubit(probeFor(book), sectionId: 'sec-a-001');
      await c.load();
      expect(c.state.items.whereType<EditorialItem>().length, 1);
      await c.close();
    });

    test('real (non-fixture) books get no editorial unless provided',
        () async {
      final c = _cubit(probeFor(twoSaintBook()));
      await c.load();
      expect(c.state.items.whereType<EditorialItem>(), isEmpty);
      await c.close();
    });

    test('an injected editorial source is used', () async {
      final c = _cubit(
        probeFor(twoSaintBook()),
        editorial: const FakeEditorialSource(),
      );
      await c.load();
      expect(c.state.items.whereType<EditorialItem>().length, 1);
      await c.close();
    });

    test('load again after an error recovers', () async {
      final book = twoSaintBook();
      final source = probeFor(book);
      final mem = source.inner as InMemoryContentSource;
      final good = mem.files['saints/saint-a.json']!;
      mem.files['saints/saint-a.json'] = '{ broken';
      final c = _cubit(source);
      await c.load();
      expect(c.state.status, LoadStatus.error);
      mem.files['saints/saint-a.json'] = good;
      await c.load();
      expect(c.state.status, LoadStatus.loaded);
      await c.close();
    });
  });
}
