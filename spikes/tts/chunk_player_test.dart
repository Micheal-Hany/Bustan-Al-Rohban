import 'package:bustan_al_rohban/spikes/tts/chunk_player.dart';
import 'package:bustan_al_rohban/spikes/tts/tts_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_tts_engine.dart';

const _text = 'أ. ب. ج.';

Future<void> _tick() => Future<void>.delayed(Duration.zero);

Future<ChunkPlayer> _player(FakeTtsEngine engine) async {
  final p = ChunkPlayer(engine);
  await p.load(_text, maxLength: 4);
  return p;
}

void main() {
  group('ChunkPlayer', () {
    test('splits the fixture text into three chunks', () async {
      final p = await _player(FakeTtsEngine());
      expect(p.chunks.map((c) => c.text), ['أ. ', 'ب. ', 'ج.']);
    });

    test('plays every chunk once, in order, then returns to idle', () async {
      final engine = FakeTtsEngine();
      final p = await _player(engine);
      await p.play();
      expect(engine.spoken, ['أ. ', 'ب. ', 'ج.']);
      expect(engine.spoken.join(), _text);
      expect(p.state, PlayerState.idle);
      expect(p.index, 0);
    });

    test('pause keeps the chunk; resume repeats it, then continues',
        () async {
      final engine = FakeTtsEngine()..autoComplete = false;
      final p = await _player(engine);

      final first = p.play();
      await _tick();
      expect(engine.spoken, ['أ. ']);
      engine.finishCurrent();
      await _tick();
      expect(engine.spoken, ['أ. ', 'ب. ']);
      expect(p.index, 1);

      await p.pause();
      await first;
      expect(p.state, PlayerState.paused);
      expect(p.index, 1);

      engine.autoComplete = true;
      await p.resume();
      expect(engine.spoken, ['أ. ', 'ب. ', 'ب. ', 'ج.']);
      expect(p.state, PlayerState.idle);
    });

    test('stop resets position and state', () async {
      final engine = FakeTtsEngine()..autoComplete = false;
      final p = await _player(engine);
      final run = p.play();
      await _tick();
      engine.finishCurrent();
      await _tick();
      await p.stop();
      await run;
      expect(p.state, PlayerState.idle);
      expect(p.index, 0);
      expect(engine.spoken.length, 2, reason: 'nothing spoken after stop');
    });

    test('an engine error puts the player in the error state', () async {
      final engine = FakeTtsEngine()..nextResult = TtsResult.error;
      final p = await _player(engine);
      await p.play();
      expect(p.state, PlayerState.error);
      expect(engine.spoken.length, 1);
    });

    test('a cancel from outside leaves the player paused and recoverable',
        () async {
      final engine = FakeTtsEngine()..nextResult = TtsResult.cancelled;
      final p = await _player(engine);
      await p.play();
      expect(p.state, PlayerState.paused);
      expect(p.index, 0);

      engine.nextResult = TtsResult.completed;
      await p.resume();
      expect(p.state, PlayerState.idle);
      expect(engine.spoken.join(), 'أ. أ. ب. ج.');
    });

    test('play while playing does not start a second loop', () async {
      final engine = FakeTtsEngine()..autoComplete = false;
      final p = await _player(engine);
      final a = p.play();
      await _tick();
      await p.play();
      expect(engine.spoken, ['أ. ']);
      await p.stop();
      await a;
    });

    test('empty text does nothing', () async {
      final engine = FakeTtsEngine();
      final p = ChunkPlayer(engine);
      await p.load('');
      await p.play();
      expect(engine.spoken, isEmpty);
      expect(p.state, PlayerState.idle);
    });

    test('whitespace-only chunks are skipped, not spoken', () async {
      final engine = FakeTtsEngine();
      final p = ChunkPlayer(engine);
      await p.load('   ');
      await p.play();
      expect(engine.spoken, isEmpty);
      expect(p.state, PlayerState.idle);
    });

    test('progress is mapped to an offset in the original text', () async {
      final engine = FakeTtsEngine()..autoComplete = false;
      final p = await _player(engine);
      final run = p.play();
      await _tick();
      engine.finishCurrent(); // now on chunk 1, which starts at offset 3
      await _tick();
      engine.onProgress!(1, 2);
      expect(p.currentOffset, p.chunks[1].start + 1);
      await p.stop();
      await run;
    });

    test('speed is passed to the engine', () async {
      final engine = FakeTtsEngine();
      final p = await _player(engine);
      await p.setRate(0.7);
      expect(engine.rates, [0.7]);
    });
  });
}
