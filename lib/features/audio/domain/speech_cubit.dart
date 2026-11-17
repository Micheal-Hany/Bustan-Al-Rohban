import 'package:flutter_bloc/flutter_bloc.dart';

import 'speech_plan.dart';
import 'tts_engine.dart';

enum SpeechStatus { idle, playing, paused, unavailable, error }

class SpeechState {
  const SpeechState({
    this.status = SpeechStatus.idle,
    this.paragraphId,
    this.rate = 1.0,
    this.support,
    this.hasPlan = false,
  });

  final SpeechStatus status;

  /// Paragraph being spoken (or paused on); null when idle.
  final String? paragraphId;

  /// Speed multiplier, 1.0 = normal.
  final double rate;

  /// Result of the last Arabic voice check (null before the first play).
  final ArabicSupport? support;
  final bool hasPlan;

  bool get isPlaying => status == SpeechStatus.playing;

  SpeechState copyWith({
    SpeechStatus? status,
    String? paragraphId,
    bool clearParagraph = false,
    double? rate,
    ArabicSupport? support,
    bool? hasPlan,
  }) =>
      SpeechState(
        status: status ?? this.status,
        paragraphId: clearParagraph ? null : (paragraphId ?? this.paragraphId),
        rate: rate ?? this.rate,
        support: support ?? this.support,
        hasPlan: hasPlan ?? this.hasPlan,
      );
}

/// Plays a [SpeechSegment] plan one utterance at a time, in order.
///
/// Android TTS has no true pause: [pause] stops the engine and keeps the
/// current segment; [play] then speaks that segment again from its start.
/// The engine is created lazily, on first use.
class SpeechCubit extends Cubit<SpeechState> {
  SpeechCubit(this._engineFactory) : super(const SpeechState());

  static const rates = [0.5, 0.75, 1.0, 1.25, 1.5];

  final TtsEngine Function() _engineFactory;
  TtsEngine? _engineInstance;
  List<SpeechSegment> _plan = const [];
  int _index = 0;
  int _generation = 0;

  TtsEngine get _engine => _engineInstance ??= _engineFactory();

  /// Replaces the plan (stops anything playing first).
  Future<void> load(List<SpeechSegment> plan) async {
    await stop();
    if (isClosed) return;
    _plan = plan;
    _index = 0;
    emit(const SpeechState().copyWith(
      rate: state.rate,
      support: state.support,
      hasPlan: plan.isNotEmpty,
    ));
  }

  /// While not playing, makes the next [play] start at this paragraph.
  void seekTo(String paragraphId) {
    if (state.status == SpeechStatus.playing) return;
    final i = _plan.indexWhere((s) => s.paragraphId == paragraphId);
    if (i >= 0) _index = i;
  }

  Future<void> play() async {
    if (_plan.isEmpty || state.status == SpeechStatus.playing) return;
    final gen = ++_generation;
    if (_index >= _plan.length) _index = 0;
    emit(state.copyWith(
      status: SpeechStatus.playing,
      paragraphId: _plan[_index].paragraphId,
    ));
    try {
      var support = state.support;
      if (support == null ||
          support == ArabicSupport.missing ||
          support == ArabicSupport.onlineOnly) {
        support = await _engine.prepareArabic();
        if (gen != _generation || isClosed) return;
        emit(state.copyWith(support: support));
      }
      if (support == ArabicSupport.missing ||
          support == ArabicSupport.onlineOnly) {
        emit(state.copyWith(
            status: SpeechStatus.unavailable, clearParagraph: true));
        return;
      }
      await _engine.setRate(state.rate);
      while (gen == _generation && _index < _plan.length) {
        final seg = _plan[_index];
        if (state.paragraphId != seg.paragraphId) {
          emit(state.copyWith(paragraphId: seg.paragraphId));
        }
        final result = await _engine.speak(seg.text);
        if (gen != _generation || isClosed) return;
        if (result == TtsResult.error) {
          emit(state.copyWith(status: SpeechStatus.error));
          return;
        }
        if (result == TtsResult.cancelled) {
          // Stopped from outside (interruption): stay recoverable.
          emit(state.copyWith(status: SpeechStatus.paused));
          return;
        }
        _index++;
      }
      if (gen == _generation && !isClosed) {
        _index = 0;
        emit(state.copyWith(status: SpeechStatus.idle, clearParagraph: true));
      }
    } catch (_) {
      if (gen == _generation && !isClosed) {
        emit(state.copyWith(status: SpeechStatus.error));
      }
    }
  }

  Future<void> pause() async {
    if (state.status != SpeechStatus.playing) return;
    _generation++;
    emit(state.copyWith(status: SpeechStatus.paused));
    await _engineInstance?.stop();
  }

  Future<void> stop() async {
    _generation++;
    _index = 0;
    final wasActive = state.status != SpeechStatus.idle ||
        state.paragraphId != null;
    if (wasActive && !isClosed) {
      emit(state.copyWith(status: SpeechStatus.idle, clearParagraph: true));
    }
    await _engineInstance?.stop();
  }

  /// Changes speed. While playing, the current segment restarts at the new
  /// speed (the engine applies a new rate only to the next utterance).
  Future<void> setRate(double rate) async {
    emit(state.copyWith(rate: rate));
    if (state.status == SpeechStatus.playing) {
      _generation++;
      emit(state.copyWith(status: SpeechStatus.paused));
      await _engineInstance?.stop();
      await play();
    }
  }

  Future<void> cycleRate() {
    final i = rates.indexOf(state.rate);
    return setRate(rates[(i + 1) % rates.length]);
  }

  @override
  Future<void> close() async {
    _generation++;
    final engine = _engineInstance;
    _engineInstance = null;
    await engine?.dispose();
    return super.close();
  }
}
