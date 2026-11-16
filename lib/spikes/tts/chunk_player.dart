import 'package:flutter/foundation.dart';

import 'chunk_splitter.dart';
import 'tts_engine.dart';

enum PlayerState { idle, playing, paused, error }

/// Spike S1 (throwaway): plays chunks one after another.
///
/// Android TTS has no true pause, so [pause] stops the engine and keeps the
/// current chunk; [resume] speaks that chunk again from its start.
class ChunkPlayer extends ChangeNotifier {
  ChunkPlayer(this._engine) {
    _engine.onProgress = (start, end) {
      if (_index < _chunks.length) {
        currentOffset = _chunks[_index].start + start;
        notifyListeners();
      }
    };
  }

  final TtsEngine _engine;
  List<TtsChunk> _chunks = const [];
  int _index = 0;
  int _generation = 0;

  PlayerState state = PlayerState.idle;

  /// Offset in the original text of the word being spoken (where reported).
  int currentOffset = 0;

  List<TtsChunk> get chunks => _chunks;
  int get index => _index;

  Future<void> load(String text, {int maxLength = 300}) async {
    await stop();
    _chunks = splitIntoChunks(text, maxLength: maxLength);
    notifyListeners();
  }

  Future<void> setRate(double rate) => _engine.setRate(rate);

  /// Starts (from the beginning when idle) or resumes (when paused).
  Future<void> play() async {
    if (state == PlayerState.playing || _chunks.isEmpty) return;
    if (_index >= _chunks.length) _index = 0;
    final gen = ++_generation;
    state = PlayerState.playing;
    notifyListeners();

    while (gen == _generation && _index < _chunks.length) {
      final chunk = _chunks[_index];
      if (!chunk.isSpeakable) {
        _index++;
        continue;
      }
      currentOffset = chunk.start;
      notifyListeners();
      final result = await _engine.speak(chunk.text);
      if (gen != _generation) return; // paused or stopped meanwhile
      if (result == TtsResult.error) {
        state = PlayerState.error;
        notifyListeners();
        return;
      }
      if (result == TtsResult.cancelled) {
        // Cancelled from outside (not by us): stay recoverable.
        state = PlayerState.paused;
        notifyListeners();
        return;
      }
      _index++;
      notifyListeners();
    }
    if (gen == _generation) {
      state = PlayerState.idle;
      _index = 0;
      notifyListeners();
    }
  }

  Future<void> resume() => play();

  Future<void> pause() async {
    if (state != PlayerState.playing) return;
    _generation++;
    state = PlayerState.paused;
    notifyListeners();
    await _engine.stop();
  }

  Future<void> stop() async {
    _generation++;
    state = PlayerState.idle;
    _index = 0;
    currentOffset = 0;
    notifyListeners();
    await _engine.stop();
  }

  @override
  void dispose() {
    _generation++;
    _engine.onProgress = null;
    super.dispose();
  }
}
