import 'package:bustan_al_rohban/core/content/content_models.dart';
import 'package:bustan_al_rohban/core/content/content_quality.dart';
import 'package:flutter_test/flutter_test.dart';

Paragraph _p(
  String id,
  String text, {
  int? page = 1,
  ParagraphKind kind = ParagraphKind.body,
}) =>
    Paragraph(id: id, order: 1, kind: kind, page: page, text: text);

ContentBook _book(List<Paragraph> paragraphs) {
  final saint = Saint(
    id: 's1',
    title: 'قديس',
    order: 1,
    aliases: const [],
    sections: [
      Section(
        id: 'sec1',
        title: 'قسم',
        order: 1,
        pageStart: null,
        pageEnd: null,
        paragraphs: paragraphs,
      ),
    ],
  );
  return ContentBook(
    manifest: ContentManifest(
      schemaVersion: 1,
      contentVersion: 1,
      bookId: 'b',
      title: 'كتاب',
      language: 'ar',
      fixture: false,
      edition: const {},
      saints: [
        SaintEntry(
          id: 's1',
          title: 'قديس',
          order: 1,
          aliases: const [],
          file: 'saints/s1.json',
          sectionCount: 1,
          paragraphCount: paragraphs.length,
        ),
      ],
      contentHash: 'x',
    ),
    saints: [saint],
  );
}

Set<String> _codes(QualityReport r) => r.issues.map((i) => i.code).toSet();

void main() {
  const checker = ContentQualityChecker();

  test('clean Arabic text gives no findings and correct stats', () {
    final r = checker.check(_book([
      _p('p1', 'هذا نص عربي سليم تمامًا.', page: 3),
      _p('p2', 'نص آخر مختلف عن الأول تمامًا.', page: 4),
    ]));
    expect(r.issues, isEmpty);
    expect(r.stats.single.paragraphs, 2);
    expect(r.stats.single.firstPage, 3);
    expect(r.stats.single.lastPage, 4);
    expect(r.totalWords, 11);
    expect(r.toMarkdown(), contains('None.'));
  });

  group('extraction problems are flagged', () {
    final cases = <String, String>{
      'empty-paragraph': '   ',
      'replacement-char': 'نص � تالف',
      'mojibake': 'Ø§Ù„Ø¨Ø³ØªØ§Ù†',
      'presentation-forms': 'ﻣﺮﺣﺒﺎ ﺑﻜﻢ',
      'invisible-chars': 'نص​مخفي',
      'control-chars': 'نص\u0001تحكم',
      'private-use-chars': 'نصخاص',
      'tatweel-run': 'نصـــــــص',
      'punctuation-run': 'نص ....... نص',
      'space-run': 'نص   فراغات',
      'latin-in-arabic': 'نص عربي مع word لاتيني',
      'very-short': 'ا',
    };
    cases.forEach((code, text) {
      test(code, () {
        final r = checker.check(_book([_p('p1', text)]));
        expect(_codes(r), contains(code));
        expect(r.issues.every((i) => !i.isError), isTrue);
        expect(r.issues.first.message, contains('p1'));
      });
    });
  });

  test('a very long paragraph and duplicate text are flagged', () {
    const small = ContentQualityChecker(longParagraphChars: 50);
    final long = 'كلمة ' * 30;
    final r = small.check(_book([
      _p('p1', long),
      _p('p2', long),
    ]));
    expect(_codes(r), containsAll(['very-long', 'duplicate-text']));
  });

  test('short repeated text is not a duplicate', () {
    final r = checker.check(_book([_p('p1', 'آمين.'), _p('p2', 'آمين.')]));
    expect(_codes(r), isNot(contains('duplicate-text')));
  });

  test('headings may be short', () {
    final r = checker.check(
        _book([_p('p1', 'ب', kind: ParagraphKind.heading)]));
    expect(_codes(r), isNot(contains('very-short')));
  });

  group('pages', () {
    test('missing pages are counted per saint', () {
      final r = checker.check(_book([
        _p('p1', 'نص عربي أول مختلف', page: null),
        _p('p2', 'نص عربي ثان مختلف', page: 2),
      ]));
      expect(r.stats.single.pagesMissing, 1);
      expect(_codes(r), contains('pages-missing'));
    });

    test('a page that goes backwards or jumps far is flagged', () {
      final back = checker.check(_book([
        _p('p1', 'نص عربي أول مختلف', page: 10),
        _p('p2', 'نص عربي ثان مختلف', page: 9),
      ]));
      expect(_codes(back), contains('page-goes-back'));
      final jump = checker.check(_book([
        _p('p1', 'نص عربي أول مختلف', page: 10),
        _p('p2', 'نص عربي ثان مختلف', page: 200),
      ]));
      expect(_codes(jump), contains('page-jump'));
    });

    test('equal and increasing pages are fine', () {
      final r = checker.check(_book([
        _p('p1', 'نص عربي أول مختلف', page: 10),
        _p('p2', 'نص عربي ثان مختلف', page: 10),
        _p('p3', 'نص عربي ثالث مختلف', page: 12),
      ]));
      expect(r.issues, isEmpty);
    });
  });

  test('markdown caps repeated findings but keeps the total', () {
    final many = [
      for (var i = 0; i < 40; i++) _p('p$i', '   ', page: 1),
    ];
    final r = checker.check(_book(many));
    final md = r.toMarkdown(maxPerCode: 5);
    expect(md, contains('`empty-paragraph` (40)'));
    expect(md, contains('and 35 more'));
    expect(r.countsByCode['empty-paragraph'], 40);
  });

  test('the checker never changes the text it reads', () {
    final book = _book([_p('p1', 'نص   مع ـــــ فراغات')]);
    checker.check(book);
    expect(book.saints.single.sections.single.paragraphs.single.text,
        'نص   مع ـــــ فراغات');
  });
}
