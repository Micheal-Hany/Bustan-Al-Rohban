import 'package:bustan_al_rohban/core/search/arabic_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeArabic', () {
    test('removes diacritics', () {
      expect(normalizeArabic('السَّلَامُ عَلَيْكُمْ'), 'السلام عليكم');
      expect(normalizeArabic('اللَّهُ'), 'الله');
    });

    test('folds alef variants to plain alef', () {
      for (final w in ['أحمد', 'إحمد', 'آحمد', 'ٱحمد', 'احمد']) {
        expect(normalizeArabic(w), 'احمد', reason: w);
      }
    });

    test('folds alef maqsura to ya', () {
      expect(normalizeArabic('على'), normalizeArabic('علي'));
      expect(normalizeArabic('هدى'), 'هدي');
    });

    test('folds ta marbuta to ha', () {
      expect(normalizeArabic('رحمة'), 'رحمه');
      expect(normalizeArabic('رحمه'), 'رحمه');
    });

    test('removes tatweel', () {
      expect(normalizeArabic('الــــله'), 'الله');
    });

    test('maps Arabic-Indic and Persian digits to ASCII', () {
      expect(normalizeArabic('١٢٣'), '123');
      expect(normalizeArabic('۴۵۶'), '456');
      expect(normalizeArabic('صفحة ٧'), 'صفحه 7');
    });

    test('lowercases Latin letters', () {
      expect(normalizeArabic('Hello مرحبا'), 'hello مرحبا');
    });

    test('punctuation and whitespace separate tokens', () {
      expect(normalizeArabic('كلمة، كلمة؟ نعم.\nسطر'), 'كلمه كلمه نعم سطر');
    });

    test('hamza on waw and ya is left unchanged', () {
      expect(normalizeArabic('مؤمن'), 'مؤمن');
      expect(normalizeArabic('سائل'), 'سائل');
    });

    test('zero-width characters do not split or change a word', () {
      expect(normalizeArabic('ك‌لمة'), 'كلمه');
      expect(tokenizeArabic('ك‌لمة').length, 1);
    });

    test('empty, whitespace-only and punctuation-only give no tokens', () {
      expect(tokenizeArabic(''), isEmpty);
      expect(tokenizeArabic('   \n '), isEmpty);
      expect(tokenizeArabic('،؟!.'), isEmpty);
      expect(tokenizeArabic('َُّ'), isEmpty, reason: 'only diacritics');
    });

    test('emoji act as separators', () {
      expect(normalizeArabic('نص 😀 نص'), 'نص نص');
    });

    test('is idempotent', () {
      const text = 'أَبُونَا الأَنْبَا؛ رَحْمَةٌ ١٢ Hello';
      final once = normalizeArabic(text);
      expect(normalizeArabic(once), once);
    });
  });

  group('tokenizeArabic ranges', () {
    test('ranges point at the original words, diacritics included', () {
      const text = 'قَالَ الرَّبُّ لِمُوسَى';
      final tokens = tokenizeArabic(text);
      expect(tokens.map((t) => t.value), ['قال', 'الرب', 'لموسي']);
      expect(text.substring(tokens[0].start, tokens[0].end), 'قَالَ');
      expect(text.substring(tokens[1].start, tokens[1].end), 'الرَّبُّ');
      expect(text.substring(tokens[2].start, tokens[2].end), 'لِمُوسَى');
    });

    test('tokenizing does not alter the original string', () {
      const text = 'السَّلَامُ  عَلَيْكُمْ\nوَرَحْمَةُ';
      final copy = String.fromCharCodes(text.codeUnits);
      tokenizeArabic(text);
      normalizeArabic(text);
      expect(text, copy);
    });

    test('ranges are ordered and non-overlapping', () {
      final tokens = tokenizeArabic('أ ب، ج. د');
      var last = 0;
      for (final t in tokens) {
        expect(t.start, greaterThanOrEqualTo(last));
        expect(t.end, greaterThan(t.start));
        last = t.end;
      }
    });
  });

  group('queryTokens', () {
    test('normalizes and removes duplicates, keeping order', () {
      expect(queryTokens('الرَّبّ  الرب قال'), ['الرب', 'قال']);
    });

    test('equivalent spellings give the same tokens', () {
      expect(queryTokens('رَحْمَة'), queryTokens('رحمه'));
      expect(queryTokens('إبونا'), queryTokens('أبونا'));
    });

    test('blank query gives no tokens', () {
      expect(queryTokens('  '), isEmpty);
    });
  });
}
