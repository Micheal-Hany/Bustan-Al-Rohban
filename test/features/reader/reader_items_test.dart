import 'package:bustan_al_rohban/core/content/content_models.dart';
import 'package:bustan_al_rohban/features/reader/domain/editorial.dart';
import 'package:bustan_al_rohban/features/reader/domain/reader_items.dart';
import 'package:flutter_test/flutter_test.dart';

Paragraph _p(String id, int? page, {String text = 'نص', bool heading = false}) =>
    Paragraph(
      id: id,
      order: 1,
      kind: heading ? ParagraphKind.heading : ParagraphKind.body,
      page: page,
      text: text,
    );

Saint _saint(List<Paragraph> ps) {
  final section = Section(
    id: 'sec-a-001',
    title: 'قسم',
    order: 1,
    pageStart: 1,
    pageEnd: 2,
    paragraphs: ps,
  );
  return Saint(
    id: 'saint-a',
    title: 'قديس',
    order: 1,
    aliases: const [],
    sections: [section],
  );
}

List<ReaderItem> _items(List<Paragraph> ps,
    {List<EditorialAddition> editorial = const []}) {
  final saint = _saint(ps);
  return buildReaderItems(
    saint: saint,
    section: saint.sections.first,
    editorial: editorial,
  );
}

String _shape(List<ReaderItem> items) => items.map((i) {
      if (i is HeaderItem) return 'H';
      if (i is EditorialItem) return 'E';
      if (i is PageMarkerItem) return 'M${i.page ?? '?'}';
      return 'P';
    }).join(' ');

void main() {
  group('buildReaderItems', () {
    test('header first, then a marker and the paragraphs', () {
      final items = _items([_p('p-000001', 1), _p('p-000002', 1)]);
      expect(_shape(items), 'H M1 P P');
      final header = items.first as HeaderItem;
      expect(header.sectionTitle, 'قسم');
      expect(header.saintTitle, 'قديس');
    });

    test('a marker appears when the page changes', () {
      final items = _items([
        _p('p-000001', 1),
        _p('p-000002', 1),
        _p('p-000003', 2),
        _p('p-000004', 2),
        _p('p-000005', 4),
      ]);
      expect(_shape(items), 'H M1 P P M2 P P M4 P');
    });

    test('unknown pages get their own marker and never a guessed number', () {
      final items = _items([
        _p('p-000001', 1),
        _p('p-000002', null),
        _p('p-000003', null),
        _p('p-000004', 1),
      ]);
      expect(_shape(items), 'H M1 P M? P P M1 P');
      final unknown = items.whereType<PageMarkerItem>().toList()[1];
      expect(unknown.page, isNull);
    });

    test('a section that starts with an unknown page starts with M?', () {
      expect(_shape(_items([_p('p-000001', null)])), 'H M? P');
    });

    test('editorial additions follow the header, before the text', () {
      final items = _items(
        [_p('p-000001', 1)],
        editorial: const [
          EditorialAddition(id: 'e1', title: 't', body: 'b'),
        ],
      );
      expect(_shape(items), 'H E M1 P');
    });

    test('paragraph order is preserved and text is untouched', () {
      const diacritics = 'السَّلَامُ  عَلَيْكُمْ\nسطر ثان ';
      final ps = [
        _p('p-000001', 1, text: diacritics),
        _p('p-000002', 1, text: 'ب', heading: true),
        _p('p-000003', 2, text: 'ج'),
      ];
      final rendered = _items(ps).whereType<ParagraphItem>().toList();
      expect(rendered.map((i) => i.paragraph.id),
          ['p-000001', 'p-000002', 'p-000003']);
      expect(rendered.first.paragraph.text, diacritics);
      expect(rendered[1].paragraph.kind, ParagraphKind.heading);
    });

    test('a section without paragraphs gives only the header', () {
      expect(_shape(_items([])), 'H');
    });
  });

  group('indexOfParagraph', () {
    test('finds the item index of a paragraph anchor', () {
      final items = _items([_p('p-000001', 1), _p('p-000002', 2)]);
      expect(_shape(items), 'H M1 P M2 P');
      expect(indexOfParagraph(items, 'p-000001'), 2);
      expect(indexOfParagraph(items, 'p-000002'), 4);
    });

    test('returns -1 for unknown ids', () {
      expect(indexOfParagraph(_items([_p('p-000001', 1)]), 'p-999999'), -1);
    });

    test('only original paragraphs have anchors', () {
      final items = _items([_p('p-000001', 1)]);
      expect(items.where((i) => i.paragraphId != null).length, 1);
    });
  });
}
