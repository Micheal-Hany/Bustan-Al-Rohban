import 'dart:async';

import 'package:bustan_al_rohban/spikes/tts/tts_engine.dart';

/// Test double. With [autoComplete] true every utterance completes at once
/// with [nextResult]; otherwise the test calls [finishCurrent].
class FakeTtsEngine implements TtsEngine {
  final List<String> spoken = [];
  final List<double> rates = [];
  bool autoComplete = true;
  TtsResult nextResult = TtsResult.completed;
  int stopCalls = 0;
  Completer<TtsResult>? pending;
  List<String> diagnoseLines = const ['engine: fake'];
  List<TtsVoice> voices = const [];

  @override
  void Function(int start, int end)? onProgress;

  @override
  Future<TtsResult> speak(String text) {
    spoken.add(text);
    if (autoComplete) return Future.value(nextResult);
    final c = Completer<TtsResult>();
    pending = c;
    return c.future;
  }

  void finishCurrent([TtsResult result = TtsResult.completed]) {
    final c = pending;
    pending = null;
    if (c != null && !c.isCompleted) c.complete(result);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    finishCurrent(TtsResult.cancelled);
  }

  @override
  Future<void> setRate(double rate) async => rates.add(rate);

  @override
  Future<void> setLanguage(String languageTag) async {}

  @override
  Future<void> setVoice(TtsVoice voice) async {}

  @override
  Future<List<TtsVoice>> arabicVoices() async => voices;

  @override
  Future<List<String>> diagnose() async => diagnoseLines;

  @override
  Future<void> dispose() async {}
}
