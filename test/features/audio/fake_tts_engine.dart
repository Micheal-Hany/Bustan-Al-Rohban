import 'dart:async';

import 'package:bustan_al_rohban/features/audio/domain/tts_engine.dart';

/// Test double. With [autoComplete] every utterance completes at once with
/// [nextResult]; otherwise the test calls [finishCurrent].
class FakeTtsEngine implements TtsEngine {
  FakeTtsEngine({this.support = ArabicSupport.offline});

  ArabicSupport support;
  final List<String> spoken = [];
  final List<double> rates = [];
  bool autoComplete = true;
  TtsResult nextResult = TtsResult.completed;
  bool throwOnSpeak = false;
  int stopCalls = 0;
  int prepareCalls = 0;
  bool disposed = false;
  Completer<TtsResult>? pending;

  @override
  void Function(int start, int end)? onProgress;

  @override
  Future<ArabicSupport> prepareArabic() async {
    prepareCalls++;
    return support;
  }

  @override
  Future<TtsResult> speak(String text) {
    spoken.add(text);
    if (throwOnSpeak) return Future.error(StateError('boom'));
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
  Future<void> setRate(double multiplier) async => rates.add(multiplier);

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}
