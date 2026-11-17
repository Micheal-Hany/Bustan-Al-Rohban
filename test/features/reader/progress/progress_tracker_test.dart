import 'package:bustan_al_rohban/core/content/content_models.dart';
import 'package:bustan_al_rohban/features/reader/domain/reader_items.dart';
import 'package:bustan_al_rohban/features/reader/progress/progress_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

List<ReaderItem> _items() {
  Paragraph p(String id, int page) => Paragraph(
        id: id,
        order: 1,
        kind: ParagraphKind.body,
        page: page,
        text: 'نص',
      );
  final section = Section(
    id: 'sec-a-001',
    title: 'ق',
    order: 1,
    pageStart: 1,
    pageEnd: 2,
    paragraphs: [p('p-000001', 1), p('p-000002', 1), p('p-000003', 2)],
  );
  final saint = Saint(
    id: 'saint-a',
    title: 'س',
    order: 1,
    aliases: const [],
    sections: [section],
  );
  // H M1 P1 P2 M2 P3
  return buildReaderItems(saint: saint, section: section);
}

const _debounce = Duration(milliseconds: 30);
const _wait = Duration(milliseconds: 120);

void main() {
  group('ProgressTracker', () {
    test('maps list indexes to paragraph ids', () {
      final t = ProgressTracker(items: _items(), onSave: (_) {});
      expect(t.paragraphAtOrAfter(0), 'p-000001', reason: 'header');
      expect(t.paragraphAtOrAfter(1), 'p-000001', reason: 'page marker');
      expect(t.paragraphAtOrAfter(3), 'p-000002');
      expect(t.paragraphAtOrAfter(4), 'p-000003', reason: 'second marker');
      expect(t.paragraphAtOrAfter(5), 'p-000003');
      expect(t.paragraphAtOrAfter(99), isNull);
      expect(t.paragraphAtOrAfter(-5), 'p-000001');
    });

    test('saves after the debounce', () async {
      final saved = <String>[];
      final t = ProgressTracker(
          items: _items(), onSave: saved.add, debounce: _debounce);
      t.visibleChanged(3);
      expect(saved, isEmpty);
      await Future<void>.delayed(_wait);
      expect(saved, ['p-000002']);
      t.dispose();
    });

    test('rapid scrolling saves only the last position', () async {
      final saved = <String>[];
      final t = ProgressTracker(
          items: _items(), onSave: saved.add, debounce: _debounce);
      t.visibleChanged(2);
      t.visibleChanged(3);
      t.visibleChanged(5);
      await Future<void>.delayed(_wait);
      expect(saved, ['p-000003']);
      t.dispose();
    });

    test('the same position is not saved twice', () async {
      final saved = <String>[];
      final t = ProgressTracker(
          items: _items(), onSave: saved.add, debounce: _debounce);
      t.visibleChanged(3);
      await Future<void>.delayed(_wait);
      t.visibleChanged(3);
      await Future<void>.delayed(_wait);
      expect(saved, ['p-000002']);
      t.dispose();
    });

    test('flush saves a pending position at once', () {
      final saved = <String>[];
      final t = ProgressTracker(items: _items(), onSave: saved.add);
      t.visibleChanged(5);
      t.flush();
      expect(saved, ['p-000003']);
    });

    test('dispose saves a pending position', () {
      final saved = <String>[];
      final t = ProgressTracker(items: _items(), onSave: saved.add);
      t.visibleChanged(3);
      t.dispose();
      expect(saved, ['p-000002']);
    });

    test('nothing pending means nothing saved', () {
      final saved = <String>[];
      final t = ProgressTracker(items: _items(), onSave: saved.add);
      t.flush();
      t.dispose();
      expect(saved, isEmpty);
    });

    test('an index past the end saves nothing', () async {
      final saved = <String>[];
      final t = ProgressTracker(
          items: _items(), onSave: saved.add, debounce: _debounce);
      t.visibleChanged(99);
      await Future<void>.delayed(_wait);
      expect(saved, isEmpty);
      t.dispose();
    });
  });
}
