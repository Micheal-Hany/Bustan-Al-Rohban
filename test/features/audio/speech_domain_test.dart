import 'package:bustan_al_rohban/core/content/content_models.dart';
import 'package:bustan_al_rohban/features/audio/domain/chunk_splitter.dart';
import 'package:bustan_al_rohban/features/audio/domain/speech_plan.dart';
import 'package:bustan_al_rohban/features/audio/domain/tts_engine.dart';
import 'package:flutter_test/flutter_test.dart';

Paragraph _p(String id, String text) => Paragraph(
    id: id, order: 1, kind: ParagraphKind.body, page: null, text: text);

void main() {
  group('splitIntoChunks', () {
    final long = List.generate(60, (i) => 'جملة رقم $i في النص.').join(' ');

    test('chunks rebuild the input exactly, in order, within the limit', () {
      final chunks = splitIntoChunks(long, maxLength: 80);
      expect(chunks.map((c) => c.text).join(), long);
      var pos = 0;
      for (final c in chunks) {
        expect(c.start, pos);
        expect(c.text.length, lessThanOrEqualTo(80));
        expect(c.text, isNotEmpty);
        pos = c.end;
      }
      expect(pos, long.length);
    });

    test('short text is one chunk; empty text is none', () {
      expect(splitIntoChunks('نص قصير').length, 1);
      expect(splitIntoChunks(''), isEmpty);
    });

    test('prefers sentence ends', () {
      final chunks = splitIntoChunks('الأولى. الثانية. الثالثة.', maxLength: 18);
      expect(chunks.first.text.trim().endsWith('.'), isTrue);
    });

    test('never splits a surrogate pair', () {
      final text = '😀' * 20;
      final chunks = splitIntoChunks(text, maxLength: 5);
      expect(chunks.map((c) => c.text).join(), text);
      for (final c in chunks) {
        expect(c.text.runes.every((r) => r == 0x1F600), isTrue);
      }
    });

    test('maxLength below 1 is rejected', () {
      expect(() => splitIntoChunks('x', maxLength: 0), throwsArgumentError);
    });
  });

  group('buildSpeechPlan', () {
    test('keeps paragraph order and tags every segment with its paragraph',
        () {
      final plan = buildSpeechPlan([
        _p('p-1', 'أول'),
        _p('p-2', 'ثان ' * 50),
        _p('p-3', 'ثالث'),
      ], maxLength: 60);
      final ids = plan.map((s) => s.paragraphId).toList();
      expect(ids.first, 'p-1');
      expect(ids.last, 'p-3');
      // ids appear in non-decreasing paragraph order
      final order = ['p-1', 'p-2', 'p-3'];
      for (var i = 1; i < ids.length; i++) {
        expect(order.indexOf(ids[i]), greaterThanOrEqualTo(order.indexOf(ids[i - 1])));
      }
      expect(plan.where((s) => s.paragraphId == 'p-2').length, greaterThan(1));
    });

    test('a paragraph is never merged with another', () {
      final plan = buildSpeechPlan([_p('a', 'س'), _p('b', 'ص')]);
      expect(plan.map((s) => s.text), ['س', 'ص']);
    });

    test('whitespace-only paragraphs are dropped', () {
      expect(buildSpeechPlan([_p('a', '   \n ')]), isEmpty);
    });

    test('the plan loses no text', () {
      final text = 'جملة. ' * 100;
      final plan = buildSpeechPlan([_p('a', text)], maxLength: 50);
      expect(plan.map((s) => s.text).join(), text);
    });
  });

  group('classifyArabic', () {
    const offline = TtsVoice(name: 'a', locale: 'ar-SA', networkRequired: false);
    const online = TtsVoice(name: 'b', locale: 'ar-EG', networkRequired: true);
    const silent = TtsVoice(name: 'c', locale: 'ar');

    test('an offline voice means offline', () {
      expect(classifyArabic([online, offline]), ArabicSupport.offline);
    });
    test('only network voices means online-only', () {
      expect(classifyArabic([online]), ArabicSupport.onlineOnly);
    });
    test('voices that do not say are unknown, not offline', () {
      expect(classifyArabic([silent]), ArabicSupport.unknown);
      expect(classifyArabic([online, silent]), ArabicSupport.unknown);
    });
    test('no voices: language flag decides', () {
      expect(classifyArabic([], languageAvailable: false),
          ArabicSupport.missing);
      expect(classifyArabic([], languageAvailable: true),
          ArabicSupport.unknown);
      expect(classifyArabic([]), ArabicSupport.unknown);
    });
  });

  test('engineRateFor maps 1.0 to the Android normal rate 0.5 and clamps', () {
    expect(engineRateFor(1.0), 0.5);
    expect(engineRateFor(1.5), 0.75);
    expect(engineRateFor(0.5), 0.25);
    expect(engineRateFor(10), 1.0);
    expect(engineRateFor(0.0), 0.1);
  });
}
