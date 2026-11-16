import 'package:bustan_al_rohban/core/content/content_models.dart';
import 'package:bustan_al_rohban/core/search/search_index.dart';
import 'package:flutter_test/flutter_test.dart';

/// (text, optional heading flag). Paragraph ids are p-000001.. in order.
Saint _saint(
  String id,
  List<(String, bool)> paragraphs, {
  int startAt = 1,
  int order = 1,
}) {
  final ps = <Paragraph>[];
  for (var i = 0; i < paragraphs.length; i++) {
    ps.add(Paragraph(
      id: 'p-${(startAt + i).toString().padLeft(6, '0')}',
      order: i + 1,
      kind: paragraphs[i].$2 ? ParagraphKind.heading : ParagraphKind.body,
      page: 1,
      text: paragraphs[i].$1,
    ));
  }
  return Saint(
    id: id,
    title: id,
    order: order,
    aliases: const [],
    sections: [
      Section(
        id: 'sec-$id-001',
        title: 's',
        order: 1,
        pageStart: 1,
        pageEnd: 1,
        paragraphs: ps,
      ),
    ],
  );
}

SearchIndex _index(List<Saint> saints) {
  final index = SearchIndex();
  for (final s in saints) {
    index.addSaint(s);
  }
  return index..finalize();
}

SearchIndex _single(List<String> texts) =>
    _index([_saint('a', [for (final t in texts) (t, false)])]);

List<String> _ids(SearchResults r) =>
    r.hits.map((h) => h.paragraph.paragraphId).toList();

void main() {
  group('matching', () {
    test('equivalent spellings find the same paragraph', () {
      final index = _single(['السَّلَامُ عَلَيْكُمْ، رَحْمَةُ اللَّهِ']);
      for (final q in ['رحمة', 'رحمه', 'رَحْمَةُ', 'الله', 'اللَّه']) {
        expect(index.search(q).total, 1, reason: q);
      }
    });

    test('alef variants match each other', () {
      final index = _single(['أبونا في البرية', 'إبونا يصلي', 'ابونا قال']);
      for (final q in ['ابونا', 'أبونا', 'إبونا', 'آبونا']) {
        expect(index.search(q).total, 3, reason: q);
      }
    });

    test('ya and alef maqsura match each other', () {
      final index = _single(['سار على الطريق', 'سار علي الطريق']);
      expect(index.search('على').total, 2);
      expect(index.search('علي').total, 2);
    });

    test('all query words must be present (AND)', () {
      final index = _single(['الرب إله', 'الرب وحده', 'إله وحده']);
      expect(_ids(index.search('الرب إله')), ['p-000001']);
      expect(index.search('الرب').total, 2);
    });

    test('no match gives total 0', () {
      final index = _single(['كلمة واحدة']);
      final r = index.search('غير موجود');
      expect(r.total, 0);
      expect(r.hits, isEmpty);
    });

    test('a missing word makes the whole query fail', () {
      final index = _single(['الرب إله']);
      expect(index.search('الرب مفقود').total, 0);
    });

    test('blank or punctuation-only queries give no results', () {
      final index = _single(['نص']);
      expect(index.search('').total, 0);
      expect(index.search('   ').tokens, isEmpty);
      expect(index.search('،؟!').total, 0);
    });

    test('prefix matches need two or more characters', () {
      final index = _single(['الله محبة']);
      expect(index.search('ال').total, 1);
      expect(index.search('ا').total, 0, reason: 'single letter is exact only');
    });

    test('a prefix query finds longer words', () {
      final index = _single(['رحمة عظيمة', 'سلام']);
      expect(_ids(index.search('رحم')), ['p-000001']);
    });

    test('an empty index returns nothing', () {
      expect(_index([]).search('نص').total, 0);
    });

    test('hits are references to the original paragraphs', () {
      final index = _index([
        _saint('a', [('نص أول', false)], startAt: 1, order: 1),
        _saint('b', [('نص ثان', false)], startAt: 2, order: 2),
      ]);
      final hits = index.search('ثان').hits;
      expect(hits.single.paragraph.saintId, 'b');
      expect(hits.single.paragraph.sectionId, 'sec-b-001');
      expect(hits.single.paragraph.paragraphId, 'p-000002');
    });

    test('works across saints', () {
      final index = _index([
        _saint('a', [('محبة', false)], startAt: 1, order: 1),
        _saint('b', [('محبة', false)], startAt: 2, order: 2),
      ]);
      expect(index.search('محبة').total, 2);
    });
  });

  group('ranking', () {
    test('an exact word ranks above a prefix match', () {
      final index = _single(['رحمة عظيمة', 'رحم عظيم']);
      // The prefix match comes first in the book; the exact one must win.
      expect(_ids(index.search('رحم')), ['p-000002', 'p-000001']);
    });

    test('more occurrences rank higher at equal length', () {
      final index = _single(['محبة سلام فرح', 'محبة محبة فرح']);
      expect(_ids(index.search('محبة')), ['p-000002', 'p-000001']);
    });

    test('an adjacent phrase in order ranks above scattered words', () {
      final index = _single(['قال موسى الرب', 'قال الرب لموسى']);
      expect(_ids(index.search('قال الرب')), ['p-000002', 'p-000001']);
    });

    test('a heading ranks above an identical body paragraph', () {
      final index = _index([
        _saint('a', [('محبة', false), ('محبة', true)]),
      ]);
      expect(_ids(index.search('محبة')), ['p-000002', 'p-000001']);
    });

    test('ties keep book order', () {
      final index = _single(['نص مكرر', 'نص مكرر', 'نص مكرر']);
      expect(_ids(index.search('مكرر')), ['p-000001', 'p-000002', 'p-000003']);
    });

    test('is deterministic', () {
      final index = _single(['أ ب', 'ب أ', 'أ', 'ب']);
      expect(_ids(index.search('أ ب')), _ids(index.search('أ ب')));
    });

    test('limit caps the hits but total counts all matches', () {
      final index = _single([for (var i = 0; i < 30; i++) 'كلمة $i']);
      final r = index.search('كلمة', limit: 10);
      expect(r.total, 30);
      expect(r.hits.length, 10);
    });
  });

  group('scale', () {
    test('5000 paragraphs index and search correctly', () {
      final texts = [
        for (var i = 0; i < 5000; i++)
          i % 100 == 0 ? 'كلمة نادرة رقم $i' : 'نص عادي رقم $i',
      ];
      final index = _single(texts);
      expect(index.documentCount, 5000);
      expect(index.search('نادرة').total, 50);
      expect(index.search('عادي').total, 4950);
    });
  });
}
