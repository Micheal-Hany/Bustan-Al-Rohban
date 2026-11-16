import 'package:bustan_al_rohban/core/search/arabic_normalizer.dart';
import 'package:bustan_al_rohban/core/search/snippet.dart';
import 'package:flutter_test/flutter_test.dart';

String _hl(SearchSnippet s, int i) =>
    s.text.substring(s.highlights[i].$1, s.highlights[i].$2);

void main() {
  group('buildSnippet', () {
    test('short text is returned whole and not truncated', () {
      const text = 'قَالَ الرَّبُّ لِمُوسَى';
      final s = buildSnippet(text, queryTokens('الرب'));
      expect(s.text, text);
      expect(s.truncatedStart, isFalse);
      expect(s.truncatedEnd, isFalse);
    });

    test('highlight covers the original word with its diacritics', () {
      const text = 'قَالَ الرَّبُّ لِمُوسَى';
      final s = buildSnippet(text, queryTokens('الرب'));
      expect(s.highlights.length, 1);
      expect(_hl(s, 0), 'الرَّبُّ');
    });

    test('a prefix query highlights the whole word', () {
      const text = 'نزلت عليهم رَحْمَةٌ كبيرة';
      final s = buildSnippet(text, queryTokens('رحم'));
      expect(_hl(s, 0), 'رَحْمَةٌ');
    });

    test('the snippet is an exact slice of the original', () {
      final text = [
        for (var i = 0; i < 60; i++) 'كلمة$i',
        'الرَّبُّ',
        for (var i = 60; i < 120; i++) 'كلمة$i',
      ].join(' ');
      final s = buildSnippet(text, queryTokens('الرب'), maxLength: 100);
      expect(text.contains(s.text), isTrue);
    });

    test('a match in a long text is centered with ellipsis flags', () {
      final text = [
        for (var i = 0; i < 60; i++) 'كلمة$i',
        'الرَّبُّ',
        for (var i = 60; i < 120; i++) 'كلمة$i',
      ].join(' ');
      final s = buildSnippet(text, queryTokens('الرب'), maxLength: 100);
      expect(s.truncatedStart, isTrue);
      expect(s.truncatedEnd, isTrue);
      expect(s.text.length, lessThan(140));
      expect(s.highlights.length, 1);
      expect(_hl(s, 0), 'الرَّبُّ');
    });

    test('a match at the start is not truncated at the start', () {
      final text = 'الرب ${List.generate(80, (i) => 'كلمة$i').join(' ')}';
      final s = buildSnippet(text, queryTokens('الرب'), maxLength: 80);
      expect(s.truncatedStart, isFalse);
      expect(s.truncatedEnd, isTrue);
      expect(_hl(s, 0), 'الرب');
    });

    test('cuts fall on word boundaries', () {
      final words = List.generate(100, (i) => 'كلمة$i');
      final text = words.join(' ');
      final s = buildSnippet(text, queryTokens('كلمة50'), maxLength: 60);
      for (final w in s.text.split(' ')) {
        expect(words.contains(w), isTrue, reason: 'partial word: $w');
      }
    });

    test('all matches inside the window are highlighted', () {
      const text = 'الله محبة الله رحمة الله نور';
      final s = buildSnippet(text, queryTokens('الله'));
      expect(s.highlights.length, 3);
    });

    test('no match starts at the beginning without highlights', () {
      final text = List.generate(80, (i) => 'كلمة$i').join(' ');
      final s = buildSnippet(text, queryTokens('غائب'), maxLength: 50);
      expect(s.highlights, isEmpty);
      expect(s.truncatedStart, isFalse);
      expect(text.startsWith(s.text), isTrue);
    });

    test('line breaks inside the text are kept', () {
      const text = 'السطر الأول\nالسطر الثاني';
      final s = buildSnippet(text, queryTokens('الثاني'));
      expect(s.text, text);
    });

    test('empty text gives an empty snippet', () {
      final s = buildSnippet('', ['نص']);
      expect(s.text, isEmpty);
      expect(s.highlights, isEmpty);
    });

    test('a match longer than the window is still fully inside', () {
      final long = 'ا' * 300;
      final s = buildSnippet('بداية $long نهاية', queryTokens(long),
          maxLength: 50);
      expect(s.highlights.length, 1);
      expect(_hl(s, 0).length, 300);
    });
  });
}
