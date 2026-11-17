import 'package:bustan_al_rohban/app/app.dart';
import 'package:bustan_al_rohban/app/strings.dart';
import 'package:bustan_al_rohban/app/theme/app_icons.dart';
import 'package:bustan_al_rohban/features/audio/domain/tts_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../library/library_test_support.dart';
import 'fake_tts_engine.dart';

const _sectionPath = '/library/book/saints/saint-a/sections/sec-a-001';

Future<void> _openReader(WidgetTester tester, FakeTtsEngine engine) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BustanApp(
    libraryRepository: repoFor(probeFor(twoSaintBook())),
    ttsEngineFactory: () => engine,
  ));
  await tester.pumpAndSettle();
  final ctx = tester.element(find.byKey(const Key('home-screen')));
  GoRouter.of(ctx).push(_sectionPath);
  await tester.pumpAndSettle();
}

IconData _playIcon(WidgetTester tester) => (tester
        .widget<IconButton>(find.byKey(const Key('tts-play-pause')))
        .icon as Icon)
    .icon!;

void main() {
  testWidgets('the reader shows the speech controls', (tester) async {
    await _openReader(tester, FakeTtsEngine());
    expect(find.byKey(const Key('speech-bar')), findsOneWidget);
    expect(_playIcon(tester), AppIcons.play);
    expect(find.text('1×'), findsOneWidget);
    expect(find.byKey(const Key('tts-message')), findsNothing);
    final stop = tester.widget<IconButton>(find.byKey(const Key('tts-stop')));
    expect(stop.onPressed, isNull); // nothing to stop yet
  });

  testWidgets('play reads the section paragraphs in order', (tester) async {
    final engine = FakeTtsEngine();
    await _openReader(tester, engine);
    await tester.tap(find.byKey(const Key('tts-play-pause')));
    await tester.pumpAndSettle();
    expect(engine.spoken, ['نص الفقرة', 'نص آخر']);
    expect(_playIcon(tester), AppIcons.play); // finished, idle again
    expect(find.byKey(const Key('tts-offline-badge')), findsOneWidget);
  });

  testWidgets('the paragraph being read is highlighted; pause and resume',
      (tester) async {
    final engine = FakeTtsEngine()..autoComplete = false;
    await _openReader(tester, engine);

    await tester.tap(find.byKey(const Key('tts-play-pause')));
    await tester.pump();
    await tester.pump();
    expect(_playIcon(tester), AppIcons.pause);
    expect(find.byKey(const Key('para-speaking-p-000001')), findsOneWidget);
    expect(find.byKey(const Key('para-speaking-p-000002')), findsNothing);

    engine.finishCurrent();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('para-speaking-p-000002')), findsOneWidget);
    expect(find.byKey(const Key('para-speaking-p-000001')), findsNothing);

    await tester.tap(find.byKey(const Key('tts-play-pause'))); // pause
    await tester.pump();
    await tester.pump();
    expect(_playIcon(tester), AppIcons.play);

    await tester.tap(find.byKey(const Key('tts-play-pause'))); // resume
    await tester.pump();
    await tester.pump();
    expect(_playIcon(tester), AppIcons.pause);
    expect(engine.spoken, ['نص الفقرة', 'نص آخر', 'نص آخر']);

    await tester.tap(find.byKey(const Key('tts-stop')));
    await tester.pump();
    await tester.pump();
    expect(_playIcon(tester), AppIcons.play);
    expect(find.byKey(const Key('para-speaking-p-000002')), findsNothing);
  });

  testWidgets('the speed button cycles and reaches the engine',
      (tester) async {
    final engine = FakeTtsEngine();
    await _openReader(tester, engine);
    await tester.tap(find.byKey(const Key('tts-speed')));
    await tester.pump();
    expect(find.text('1.25×'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tts-play-pause')));
    await tester.pumpAndSettle();
    expect(engine.rates.last, 1.25);
  });

  testWidgets('no Arabic voice: clear message, nothing spoken',
      (tester) async {
    final engine = FakeTtsEngine(support: ArabicSupport.missing);
    await _openReader(tester, engine);
    await tester.tap(find.byKey(const Key('tts-play-pause')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.ttsMissingVoice), findsOneWidget);
    expect(engine.spoken, isEmpty);
    expect(find.byKey(const Key('tts-offline-badge')), findsNothing);
  });

  testWidgets('online-only voice: explains, never switches silently',
      (tester) async {
    final engine = FakeTtsEngine(support: ArabicSupport.onlineOnly);
    await _openReader(tester, engine);
    await tester.tap(find.byKey(const Key('tts-play-pause')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.ttsOnlineOnly), findsOneWidget);
    expect(engine.spoken, isEmpty);
  });

  testWidgets('unknown support plays without the offline badge',
      (tester) async {
    final engine = FakeTtsEngine(support: ArabicSupport.unknown);
    await _openReader(tester, engine);
    await tester.tap(find.byKey(const Key('tts-play-pause')));
    await tester.pumpAndSettle();
    expect(engine.spoken, isNotEmpty);
    expect(find.byKey(const Key('tts-offline-badge')), findsNothing);
  });

  testWidgets('an engine error shows a message and can be retried',
      (tester) async {
    final engine = FakeTtsEngine()..nextResult = TtsResult.error;
    await _openReader(tester, engine);
    await tester.tap(find.byKey(const Key('tts-play-pause')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.ttsError), findsOneWidget);

    engine.nextResult = TtsResult.completed;
    await tester.tap(find.byKey(const Key('tts-play-pause')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.ttsError), findsNothing);
  });

  testWidgets('leaving the reader stops the speech', (tester) async {
    final engine = FakeTtsEngine()..autoComplete = false;
    await _openReader(tester, engine);
    await tester.tap(find.byKey(const Key('tts-play-pause')));
    await tester.pump();
    final before = engine.stopCalls;
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(engine.stopCalls, greaterThan(before));
    expect(find.byKey(const Key('reader-screen')), findsNothing);
  });
}
