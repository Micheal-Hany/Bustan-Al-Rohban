import 'package:bustan_al_rohban/features/bookmarks/domain/bookmark_store.dart';
import 'package:bustan_al_rohban/features/reader/progress/reading_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/content/test_support.dart';
import '../library/library_test_support.dart';
import '../search/search_test_support.dart';

void main() {
  group('LibraryRepository.locate', () {
    test('finds a paragraph with its saint and section', () async {
      final repo = repoFor(probeFor(searchBook()));
      final loc = (await repo.locate('p-000004'))!;
      expect(loc.saint.id, 'saint-a');
      expect(loc.section.id, 'sec-a-002');
      expect(loc.paragraph.id, 'p-000004');
    });

    test('a correct saint hint avoids loading other saints', () async {
      final source = probeFor(searchBook());
      final repo = repoFor(source);
      await repo.locate('p-000005', saintHint: 'saint-b');
      expect(source.reads.containsKey('saints/saint-a.json'), isFalse);
    });

    test('a wrong hint falls back to searching every saint', () async {
      final repo = repoFor(probeFor(searchBook()));
      final loc = await repo.locate('p-000005', saintHint: 'saint-a');
      expect(loc!.saint.id, 'saint-b');
    });

    test('an unknown paragraph gives null', () async {
      final repo = repoFor(probeFor(searchBook()));
      expect(await repo.locate('p-999999'), isNull);
    });

    test('a corrupt saint is skipped, not fatal', () async {
      final source = probeFor(searchBook());
      (source.inner as InMemoryContentSource).files['saints/saint-a.json'] =
          '{ broken';
      final repo = repoFor(source);
      final loc = await repo.locate('p-000005');
      expect(loc!.saint.id, 'saint-b');
      expect(await repo.locate('p-000001'), isNull);
    });
  });

  group('References survive re-ordering of content', () {
    // Version 1 and version 2 of the same fixture: saints swapped, a section
    // renamed and renumbered, and a paragraph moved into another section.
    // Paragraph IDs are unchanged.
    TestBook v2() => buildBook([
          saintJson(
            id: 'saint-b',
            order: 1,
            title: 'القديس الثاني',
            sections: [
              sectionJson(
                id: 'sec-b-001',
                order: 1,
                title: 'قسم ب',
                paragraphs: [
                  paraJson(id: 'p-000005', order: 1, page: 5, text: 'محبة'),
                  paraJson(id: 'p-000006', order: 2, page: 6, text: 'صلاة'),
                ],
              ),
            ],
          ),
          saintJson(
            id: 'saint-a',
            order: 2,
            title: 'القديس الأول',
            sections: [
              sectionJson(
                id: 'sec-a-renamed',
                order: 1,
                title: 'قسم بعد إعادة الترتيب',
                paragraphs: [
                  paraJson(id: 'p-000001', order: 1, page: 1, text: 'أول'),
                  // Moved here from the old second section.
                  paraJson(
                      id: 'p-000004',
                      order: 2,
                      page: 1,
                      text: 'قال الرب لموسى كلمة'),
                ],
              ),
            ],
          ),
        ]);

    test('a bookmark made before still resolves after re-ordering',
        () async {
      // Created against version 1: saint-a / sec-a-002 / p-000004.
      final store = InMemoryBookmarkStore();
      final created = await store.add(
        saintId: 'saint-a',
        sectionId: 'sec-a-002',
        paragraphId: 'p-000004',
        contentVersion: 1,
      );

      final repoV2 = repoFor(probeFor(v2()));
      final loc = await repoV2.locate(
        created.paragraphId,
        saintHint: created.saintId,
      );
      expect(loc, isNotNull);
      expect(loc!.section.id, 'sec-a-renamed');
      expect(loc.paragraph.text, 'قال الرب لموسى كلمة');
      // The stored reference itself is untouched: only the ID matters.
      expect(created.paragraphId, 'p-000004');
    });

    test('reading progress also resolves after re-ordering', () async {
      final progress = InMemoryProgressStore();
      await progress.save(ReadingProgress(
        saintId: 'saint-a',
        sectionId: 'sec-a-002', // no longer exists in version 2
        paragraphId: 'p-000004',
        offset: 0,
        contentVersion: 1,
        updatedAt: DateTime.utc(2026, 1, 1),
      ));
      final last = (await progress.last())!;
      final loc = await repoFor(probeFor(v2()))
          .locate(last.paragraphId, saintHint: last.saintId);
      expect(loc!.section.id, 'sec-a-renamed');
    });
  });
}
