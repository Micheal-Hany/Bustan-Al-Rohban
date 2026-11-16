import 'package:bustan_al_rohban/spikes/tts/tts_engine.dart';
import 'package:bustan_al_rohban/spikes/tts/tts_spike_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_tts_engine.dart';

Future<FakeTtsEngine> _pump(WidgetTester tester,
    {bool autoComplete = true, List<TtsVoice> voices = const []}) async {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final engine = FakeTtsEngine()
    ..autoComplete = autoComplete
    ..voices = voices;
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('ar'),
    home: TtsSpikeScreen(engineFactory: () => engine),
  ));
  await tester.pumpAndSettle();
  return engine;
}

String _status(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('tts-status'))).data!;

void main() {
  testWidgets('diagnostics are shown after tapping the check button',
      (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('tts-report')), findsNothing);
    await tester.tap(find.byKey(const Key('tts-diagnose-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('engine: fake'), findsOneWidget);
  });

  testWidgets('play speaks the whole text in order and ends idle',
      (tester) async {
    final engine = await _pump(tester);
    final text =
        tester.widget<TextField>(find.byKey(const Key('tts-text'))).controller!.text;
    await tester.tap(find.byKey(const Key('tts-play')));
    await tester.pumpAndSettle();
    expect(engine.spoken.join(), text);
    expect(_status(tester), startsWith('idle'));
  });

  testWidgets('pause, resume and stop change the state', (tester) async {
    final engine = await _pump(tester, autoComplete: false);
    await tester.tap(find.byKey(const Key('tts-play')));
    await tester.pump();
    await tester.pump();
    expect(_status(tester), startsWith('playing'));

    await tester.tap(find.byKey(const Key('tts-pause')));
    await tester.pump();
    await tester.pump();
    expect(_status(tester), startsWith('paused'));

    await tester.tap(find.byKey(const Key('tts-resume')));
    await tester.pump();
    await tester.pump();
    expect(_status(tester), startsWith('playing'));
    expect(engine.spoken.length, 2, reason: 'first chunk is repeated');

    await tester.tap(find.byKey(const Key('tts-stop')));
    await tester.pump();
    await tester.pump();
    expect(_status(tester), startsWith('idle'));
  });

  testWidgets('sample buttons fill the text field', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('tts-sample-plain')));
    await tester.pump();
    final c = tester
        .widget<TextField>(find.byKey(const Key('tts-text')))
        .controller!;
    expect(c.text, 'السلام عليكم ورحمة الله وبركاته.');
  });

  testWidgets('voice list appears only when Arabic voices exist',
      (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('tts-voice')), findsNothing);
  });

  testWidgets('voices are offered when the engine reports some',
      (tester) async {
    await _pump(tester, voices: const [
      TtsVoice(name: 'ar-voice-1', locale: 'ar-SA', networkRequired: false),
    ]);
    expect(find.byKey(const Key('tts-voice')), findsOneWidget);
  });
}
