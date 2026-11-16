import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

/// Spike S1 (throwaway): thin interface over the platform TTS so the chunk
/// player can be unit-tested without a device.
enum TtsResult { completed, cancelled, error }

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
  String toString() => '$name ($locale'
      '${networkRequired == null ? '' : ', network: $networkRequired'})';
}

abstract class TtsEngine {
  /// Called with offsets (start, end) inside the text of the utterance being
  /// spoken, where the platform reports progress.
  void Function(int start, int end)? onProgress;

  Future<void> setRate(double rate);
  Future<void> setLanguage(String languageTag);
  Future<void> setVoice(TtsVoice voice);
  Future<List<TtsVoice>> arabicVoices();

  /// Human-readable lines describing what this device offers.
  Future<List<String>> diagnose();

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

  @override
  Future<void> setRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  @override
  Future<void> setLanguage(String languageTag) async {
    await _tts.setLanguage(languageTag);
  }

  @override
  Future<void> setVoice(TtsVoice voice) async {
    await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
  }

  @override
  Future<List<TtsVoice>> arabicVoices() async {
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
          networkRequired: net == null ? null : '$net' == '1' || '$net' == 'true',
        ));
      }
    }
    return result;
  }

  Future<String> _try(String label, Future<Object?> Function() fn) async {
    try {
      return '$label: ${await fn()}';
    } catch (e) {
      return '$label: error ($e)';
    }
  }

  @override
  Future<List<String>> diagnose() async {
    final lines = <String>[
      await _try('default engine', () => _tts.getDefaultEngine),
      await _try('engines', () => _tts.getEngines),
      await _try('max input length', () => _tts.getMaxSpeechInputLength),
      await _try('Arabic languages', () async {
        final all = await _tts.getLanguages;
        return all is List
            ? all.where((l) => '$l'.toLowerCase().startsWith('ar')).toList()
            : all;
      }),
    ];
    for (final tag in const ['ar', 'ar-SA', 'ar-EG']) {
      lines.add(await _try(
          'available $tag', () => _tts.isLanguageAvailable(tag)));
      lines.add(await _try(
          'installed $tag', () => _tts.isLanguageInstalled(tag)));
    }
    try {
      final voices = await arabicVoices();
      lines.add('Arabic voices: ${voices.length}');
      lines.addAll(voices.map((v) => '  - $v'));
    } catch (e) {
      lines.add('Arabic voices: error ($e)');
    }
    return lines;
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
