import 'package:bustan_al_rohban/features/audio/domain/speech_cubit.dart';
import 'package:bustan_al_rohban/features/audio/domain/speech_plan.dart';
import 'package:bustan_al_rohban/features/audio/domain/tts_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_tts_engine.dart';

List<SpeechSegment> _plan() => const [
      SpeechSegment(paragraphId: 'p1', text: 'one'),
      SpeechSegment(paragraphId: 'p1', text: 'two'),
      SpeechSegment(paragraphId: 'p2', text: 'three'),
      SpeechSegment(paragraphId: 'p3', text: 'four'),
    ];

Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeTtsEngine engine;
  late SpeechCubit cubit;
  var created = 0;

  setUp(() {
    created = 0;
    engine = FakeTtsEngine();
    cubit = SpeechCubit(() {
      created++;
      return engine;
    });
  });

  tearDown(() => cubit.close());

  test('the engine is created lazily, only when speaking', () async {
    await cubit.load(_plan());
    await cubit.stop();
    expect(created, 0);
    await cubit.play();
    expect(created, 1);
  });

  test('plays every segment once, in order, then returns to idle', () async {
    await cubit.load(_plan());
    final seen = <String?>[];
    final sub = cubit.stream.listen((s) => seen.add(s.paragraphId));
    await cubit.play();
    await _tick();
    await sub.cancel();
    expect(engine.spoken, ['one', 'two', 'three', 'four']);
    expect(cubit.state.status, SpeechStatus.idle);
    expect(cubit.state.paragraphId, isNull);
    expect(seen.where((e) => e != null).toSet(), {'p1', 'p2', 'p3'});
  });

  test('can be played again from the start after finishing', () async {
    await cubit.load(_plan());
    await cubit.play();
    await cubit.play();
    expect(engine.spoken.length, 8);
    expect(engine.spoken.sublist(4), ['one', 'two', 'three', 'four']);
  });

  test('state follows the paragraph being spoken', () async {
    engine.autoComplete = false;
    await cubit.load(_plan());
    final run = cubit.play();
    await _tick();
    expect(cubit.state.status, SpeechStatus.playing);
    expect(cubit.state.paragraphId, 'p1');
    engine.finishCurrent();
    await _tick();
    engine.finishCurrent();
    await _tick();
    expect(cubit.state.paragraphId, 'p2');
    await cubit.stop();
    await run;
  });

  test('pause keeps the position; resume repeats only the current segment',
      () async {
    engine.autoComplete = false;
    await cubit.load(_plan());
    final run = cubit.play();
    await _tick();
    engine.finishCurrent(); // "one" done
    await _tick();
    expect(engine.spoken, ['one', 'two']);

    await cubit.pause();
    await run;
    expect(cubit.state.status, SpeechStatus.paused);
    expect(cubit.state.paragraphId, 'p1');

    final run2 = cubit.play(); // resume
    await _tick();
    expect(engine.spoken, ['one', 'two', 'two']); // no skip, one repeat
    expect(cubit.state.status, SpeechStatus.playing);
    engine.finishCurrent();
    await _tick();
    engine.finishCurrent();
    await _tick();
    engine.finishCurrent();
    await run2;
    expect(engine.spoken, ['one', 'two', 'two', 'three', 'four']);
    expect(cubit.state.status, SpeechStatus.idle);
  });

  test('stop resets to the beginning', () async {
    engine.autoComplete = false;
    await cubit.load(_plan());
    final run = cubit.play();
    await _tick();
    engine.finishCurrent();
    await _tick();
    await cubit.stop();
    await run;
    expect(cubit.state.status, SpeechStatus.idle);
    expect(cubit.state.paragraphId, isNull);
    engine.spoken.clear();
    engine.autoComplete = true;
    await cubit.play();
    expect(engine.spoken.first, 'one');
  });

  test('seekTo sets the start while idle, and is ignored while playing',
      () async {
    await cubit.load(_plan());
    cubit.seekTo('p2');
    await cubit.play();
    expect(engine.spoken, ['three', 'four']);

    engine.spoken.clear();
    engine.autoComplete = false;
    cubit.seekTo('p1');
    final run = cubit.play();
    await _tick();
    cubit.seekTo('p3'); // ignored: already playing
    await cubit.stop();
    await run;
    expect(engine.spoken, ['one']);
  });

  test('speed: applied before playing and cycles through the steps', () async {
    await cubit.load(_plan());
    await cubit.cycleRate(); // 1.0 -> 1.25
    expect(cubit.state.rate, 1.25);
    await cubit.play();
    expect(engine.rates.last, 1.25);
    await cubit.cycleRate(); // 1.5
    await cubit.cycleRate(); // wraps to 0.5
    expect(cubit.state.rate, 0.5);
  });

  test('changing speed while playing restarts the current segment at the new '
      'speed', () async {
    engine.autoComplete = false;
    await cubit.load(_plan());
    final run = cubit.play();
    await _tick();
    final change = cubit.setRate(1.5);
    await _tick();
    expect(engine.rates.last, 1.5);
    expect(engine.spoken, ['one', 'one']);
    expect(cubit.state.status, SpeechStatus.playing);
    await cubit.stop();
    await change;
    await run;
  });

  group('Arabic voice checks', () {
    test('missing voice: nothing is spoken, clear state, retryable', () async {
      engine.support = ArabicSupport.missing;
      await cubit.load(_plan());
      await cubit.play();
      expect(cubit.state.status, SpeechStatus.unavailable);
      expect(cubit.state.support, ArabicSupport.missing);
      expect(engine.spoken, isEmpty);

      engine.support = ArabicSupport.offline; // user installed a voice
      await cubit.play();
      expect(engine.prepareCalls, 2);
      expect(engine.spoken.length, 4);
    });

    test('online-only voice is never used silently', () async {
      engine.support = ArabicSupport.onlineOnly;
      await cubit.load(_plan());
      await cubit.play();
      expect(cubit.state.status, SpeechStatus.unavailable);
      expect(cubit.state.support, ArabicSupport.onlineOnly);
      expect(engine.spoken, isEmpty);
    });

    test('unknown support still plays but does not claim offline', () async {
      engine.support = ArabicSupport.unknown;
      await cubit.load(_plan());
      await cubit.play();
      expect(engine.spoken.length, 4);
      expect(cubit.state.support, ArabicSupport.unknown);
    });

    test('the voice is checked once while it works', () async {
      await cubit.load(_plan());
      await cubit.play();
      await cubit.play();
      expect(engine.prepareCalls, 1);
    });
  });

  group('errors and interruptions', () {
    test('an engine error stops with an error state and can be retried',
        () async {
      engine.nextResult = TtsResult.error;
      await cubit.load(_plan());
      await cubit.play();
      expect(cubit.state.status, SpeechStatus.error);
      expect(engine.spoken, ['one']);

      engine.nextResult = TtsResult.completed;
      await cubit.play();
      expect(cubit.state.status, SpeechStatus.idle);
      expect(engine.spoken.sublist(1), ['one', 'two', 'three', 'four']);
    });

    test('an exception from the engine becomes an error state', () async {
      engine.throwOnSpeak = true;
      await cubit.load(_plan());
      await cubit.play();
      expect(cubit.state.status, SpeechStatus.error);
    });

    test('an external cancel (interruption) leaves it paused and recoverable',
        () async {
      engine.autoComplete = false;
      await cubit.load(_plan());
      final run = cubit.play();
      await _tick();
      engine.finishCurrent(TtsResult.cancelled);
      await run;
      expect(cubit.state.status, SpeechStatus.paused);
      expect(cubit.state.paragraphId, 'p1');
      engine.autoComplete = true;
      await cubit.play();
      expect(cubit.state.status, SpeechStatus.idle);
    });
  });

  test('play with an empty plan does nothing', () async {
    await cubit.load(const []);
    await cubit.play();
    expect(cubit.state.status, SpeechStatus.idle);
    expect(cubit.state.hasPlan, isFalse);
    expect(created, 0);
  });

  test('loading a new plan stops the old one and keeps the chosen speed',
      () async {
    engine.autoComplete = false;
    await cubit.load(_plan());
    await cubit.setRate(1.5);
    final run = cubit.play();
    await _tick();
    await cubit.load(const [SpeechSegment(paragraphId: 'x', text: 'new')]);
    await run;
    expect(cubit.state.status, SpeechStatus.idle);
    expect(cubit.state.rate, 1.5);
    expect(cubit.state.hasPlan, isTrue);
  });

  test('a plan is tied to its key (owns)', () async {
    await cubit.load(_plan(), key: 'saint-a/sec-1');
    expect(cubit.owns('saint-a/sec-1'), isTrue);
    expect(cubit.owns('saint-a/sec-2'), isFalse);
    await cubit.load(const [SpeechSegment(paragraphId: 'z', text: 'z')],
        key: 'saint-a/sec-2');
    expect(cubit.owns('saint-a/sec-1'), isFalse);
  });

  test('closing the cubit disposes the engine', () async {
    await cubit.load(_plan());
    await cubit.play();
    await cubit.close();
    expect(engine.disposed, isTrue);
  });

  test('a long section is spoken without repeats or skips', () async {
    final plan = [
      for (var i = 0; i < 200; i++)
        SpeechSegment(paragraphId: 'p${i ~/ 5}', text: 's$i'),
    ];
    await cubit.load(plan);
    await cubit.play();
    expect(engine.spoken, [for (var i = 0; i < 200; i++) 's$i']);
  });
}
