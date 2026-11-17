import 'package:bustan_al_rohban/features/ai_chat/domain/chat_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deriveTitle', () {
    test('short text is kept as is (whitespace collapsed)', () {
      expect(deriveTitle('  ما هو   الصوم؟\n'), 'ما هو الصوم؟');
    });

    test('exactly the maximum length is not shortened', () {
      final s = 'ا' * chatTitleMaxLength;
      expect(deriveTitle(s), s);
    });

    test('long text is cut at a word boundary with an ellipsis', () {
      final t = deriveTitle('كلمة ' * 30);
      expect(t.endsWith('…'), isTrue);
      expect(t.endsWith(' …'), isFalse);
      expect(t.runes.length, lessThanOrEqualTo(chatTitleMaxLength + 1));
      expect(t.replaceAll('…', '').trim().split(' ').every((w) => w == 'كلمة'),
          isTrue);
    });

    test('a long text without spaces is hard-cut', () {
      final t = deriveTitle('ا' * 100);
      expect(t.runes.length, chatTitleMaxLength + 1);
      expect(t.endsWith('…'), isTrue);
    });

    test('never splits a surrogate pair', () {
      final t = deriveTitle('😀' * 100);
      expect(t.replaceAll('…', '').runes.every((r) => r == 0x1F600), isTrue);
    });

    test('a custom length is respected', () {
      expect(deriveTitle('أول ثان ثالث رابع', maxLength: 12), 'أول ثان ثالث…');
    });
  });
}
