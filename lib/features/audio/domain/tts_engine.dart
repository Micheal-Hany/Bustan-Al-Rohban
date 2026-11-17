import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

enum TtsResult { completed, cancelled, error }

/// Whether the device can speak Arabic, and how.
enum ArabicSupport {
  /// At least one Arabic voice is reported as working without internet.
  offline,

  /// Arabic voices exist but all need the network. Never used silently.
  onlineOnly,

  /// No Arabic voice or language is available.
  missing,

  /// The engine does not say (no voice list). Playback is attempted but
  /// offline operation is not promised.
  unknown,
}

class TtsVoice {
  const TtsVoice({
    required this.name,
    required this.locale,
    this.networkRequired,
  });

  final String name;
  final String locale;

  /// null when the platform does not say.
  final bool? networkRequired;

  @override
  String toString() => '$name ($locale, network: $networkRequired)';
}

/// Decides [ArabicSupport] from what the engine reports.
/// [languageAvailable] is the engine's answer for plain `ar` (null = unknown).
ArabicSupport classifyArabic(
  List<TtsVoice> arabicVoices, {
  bool? languageAvailable,
}) {
  if (arabicVoices.isEmpty) {
    if (languageAvailable == false) return ArabicSupport.missing;
    return ArabicSupport.unknown;
  }
  if (arabicVoices.any((v) => v.networkRequired == false)) {
    return ArabicSupport.offline;
  }
  if (arabicVoices.any((v) => v.networkRequired == null)) {
    return ArabicSupport.unknown;
  }
  return ArabicSupport.onlineOnly;
}

/// Maps a speed multiplier (1.0 = normal) to the Android `flutter_tts` rate,
/// where 0.5 is normal speed.
double engineRateFor(double multiplier) =>
    (0.5 * multiplier).clamp(0.1, 1.0).toDouble();

/// Thin interface over the platform TTS so the player is testable without a
/// device.
abstract class TtsEngine {
  /// Offsets (start, end) inside the utterance being spoken, where the
  /// platform reports progress.
  void Function(int start, int end)? onProgress;

  /// Checks Arabic availability and selects an offline Arabic voice when one
  /// exists (so the engine never silently switches to an online voice).
  Future<ArabicSupport> prepareArabic();

  /// Speed multiplier, 1.0 = normal.
  Future<void> setRate(double multiplier);

  /// Completes when the utterance finishes, is stopped, or fails.
  Future<TtsResult> speak(String text);

  Future<void> stop();
  Future<void> dispose();
}

/// Real engine on top of `flutter_tts`. Only our own [stop] produces
/// [TtsResult.cancelled]; the plugin's cancel callback is deliberately not
/// used because a late cancel from an old utterance could end a new one.
class FlutterTtsEngine implements TtsEngine {
  FlutterTtsEngine() : _tts = FlutterTts() {
    _tts.setCompletionHandler(() => _finish(TtsResult.completed));
    _tts.setErrorHandler((message) {
      lastError = '$message';
      _finish(TtsResult.error);
    });
    _tts.setProgressHandler((text, start, end, word) {
      onProgress?.call(start, end);
    });
  }

  final FlutterTts _tts;
  Completer<TtsResult>? _pending;
  String? lastError;

  @override
  void Function(int start, int end)? onProgress;

  void _finish(TtsResult result) {
    final c = _pending;
    _pending = null;
    if (c != null && !c.isCompleted) c.complete(result);
  }

  Future<List<TtsVoice>> _arabicVoices() async {
    final raw = await _tts.getVoices;
    final result = <TtsVoice>[];
    if (raw is List) {
      for (final v in raw) {
        if (v is! Map) continue;
        final locale = '${v['locale'] ?? ''}';
        if (!locale.toLowerCase().startsWith('ar')) continue;
        final net = v['network_required'];
        result.add(TtsVoice(
          name: '${v['name'] ?? ''}',
          locale: locale,
          networkRequired:
              net == null ? null : '$net' == '1' || '$net' == 'true',
        ));
      }
    }
    return result;
  }

  @override
  Future<ArabicSupport> prepareArabic() async {
    var voices = const <TtsVoice>[];
    try {
      voices = await _arabicVoices();
    } catch (_) {}
    bool? available;
    try {
      final r = await _tts.isLanguageAvailable('ar');
      available = r == true || r == 1;
    } catch (_) {}
    final support = classifyArabic(voices, languageAvailable: available);
    try {
      if (support == ArabicSupport.offline) {
        final v = voices.firstWhere((v) => v.networkRequired == false);
        await _tts.setVoice({'name': v.name, 'locale': v.locale});
      } else if (support == ArabicSupport.unknown) {
        await _tts.setLanguage('ar');
      }
    } catch (_) {}
    return support;
  }

  @override
  Future<void> setRate(double multiplier) async {
    await _tts.setSpeechRate(engineRateFor(multiplier));
  }

  @override
  Future<TtsResult> speak(String text) async {
    final c = Completer<TtsResult>();
    _pending = c;
    final started = await _tts.speak(text);
    if (started != 1) {
      lastError = 'speak returned $started';
      _finish(TtsResult.error);
    }
    return c.future;
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    _finish(TtsResult.cancelled);
  }

  @override
  Future<void> dispose() async {
    await stop();
  }
}
