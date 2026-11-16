import 'package:bustan_al_rohban/spikes/tts/chunk_splitter.dart';
import 'package:flutter_test/flutter_test.dart';

String _joined(List<TtsChunk> c) => c.map((x) => x.text).join();

void _expectInvariants(String text, List<TtsChunk> chunks, int maxLength) {
  expect(_joined(chunks), text, reason: 'no text lost or reordered');
  var expectedStart = 0;
  for (var i = 0; i < chunks.length; i++) {
    final c = chunks[i];
    expect(c.index, i);
    expect(c.start, expectedStart, reason: 'contiguous');
    expect(c.text.isNotEmpty, isTrue);
    expect(c.text.length, lessThanOrEqualTo(maxLength));
    expect(text.substring(c.start, c.end), c.text);
    expectedStart = c.end;
  }
  expect(expectedStart, text.length);
}

void main() {
  group('splitIntoChunks', () {
    test('empty text gives no chunks', () {
      expect(splitIntoChunks(''), isEmpty);
    });

    test('short text is one chunk', () {
      final chunks = splitIntoChunks('نص قصير.');
      expect(chunks.length, 1);
      expect(chunks.single.text, 'نص قصير.');
    });

    test('rejects maxLength below 1', () {
      expect(() => splitIntoChunks('x', maxLength: 0), throwsArgumentError);
    });

    test('prefers sentence boundaries', () {
      const text = 'جملة أولى. جملة ثانية طويلة قليلا.';
      final chunks = splitIntoChunks(text, maxLength: 20);
      expect(chunks.first.text, 'جملة أولى. ');
      _expectInvariants(text, chunks, 20);
    });

    test('uses Arabic question mark and semicolon', () {
      const text = 'هل هذا سؤال؟ نعم؛ هذا جواب طويل بما يكفي للقطع.';
      final chunks = splitIntoChunks(text, maxLength: 16);
      _expectInvariants(text, chunks, 16);
      expect(chunks.first.text, 'هل هذا سؤال؟ ');
    });

    test('falls back to commas then spaces', () {
      const text = 'كلمة، كلمة، كلمة كلمة كلمة كلمة كلمة كلمة';
      final chunks = splitIntoChunks(text, maxLength: 15);
      _expectInvariants(text, chunks, 15);
      expect(chunks.length, greaterThan(2));
    });

    test('a word longer than maxLength is hard cut without loss', () {
      final text = 'ا' * 25;
      final chunks = splitIntoChunks(text, maxLength: 10);
      _expectInvariants(text, chunks, 10);
      expect(chunks.length, 3);
    });

    test('never splits a surrogate pair', () {
      final text = '😀' * 10; // each emoji is 2 UTF-16 units
      final chunks = splitIntoChunks(text, maxLength: 5);
      _expectInvariants(text, chunks, 5);
      for (final c in chunks) {
        expect(c.text.runes.length * 2, c.text.length,
            reason: 'only whole code points');
      }
    });

    test('maxLength 1 still terminates and keeps everything', () {
      const text = 'أبجد هوز.';
      _expectInvariants(text, splitIntoChunks(text, maxLength: 1), 1);
    });

    test('diacritics and line breaks are preserved exactly', () {
      const text = 'السَّلَامُ عَلَيْكُمْ.\nوَرَحْمَةُ اللَّهِ.\r\nتَمَّ.';
      final chunks = splitIntoChunks(text, maxLength: 12);
      _expectInvariants(text, chunks, 12);
    });

    test('long passage keeps order across many chunks', () {
      final text = List.generate(
        200,
        (i) => 'هذه الجملة رقم $i للتجربة فقط.',
      ).join(' ');
      for (final max in [50, 120, 300, 4000]) {
        _expectInvariants(text, splitIntoChunks(text, maxLength: max), max);
      }
    });

    test('whitespace-only text is kept but not speakable', () {
      final chunks = splitIntoChunks('   ');
      expect(_joined(chunks), '   ');
      expect(chunks.every((c) => !c.isSpeakable), isTrue);
    });

    test('is deterministic', () {
      const text = 'جملة. جملة أخرى، وجملة ثالثة؟ نعم.';
      final a = splitIntoChunks(text, maxLength: 12).map((c) => c.text);
      final b = splitIntoChunks(text, maxLength: 12).map((c) => c.text);
      expect(a.toList(), b.toList());
    });
  });
}
