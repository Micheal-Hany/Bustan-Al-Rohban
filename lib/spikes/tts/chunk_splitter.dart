/// Spike S1 (throwaway): splits long text into TTS-safe chunks.
///
/// Guarantees (covered by tests):
/// - concatenating all chunk texts gives back the input exactly;
/// - chunks are contiguous, in order, non-empty, and at most [maxLength] long;
/// - a surrogate pair is never split;
/// - breaks prefer sentence ends, then commas/colons, then spaces.
class TtsChunk {
  const TtsChunk({
    required this.index,
    required this.start,
    required this.end,
    required this.text,
  });

  final int index;

  /// Offsets into the original text: [start, end).
  final int start;
  final int end;
  final String text;

  /// False for whitespace-only chunks (kept so no text is lost, but skipped
  /// when speaking).
  bool get isSpeakable => text.trim().isNotEmpty;

  @override
  String toString() => 'TtsChunk($index, $start-$end)';
}

const _sentenceEnds = {'.', '!', '?', '؟', '؛', ';', '…', '\n', '۔'};
const _softBreaks = {'،', ',', ':'};

bool _isSpace(String c) => c.trim().isEmpty;

List<TtsChunk> splitIntoChunks(String text, {int maxLength = 300}) {
  if (maxLength < 1) {
    throw ArgumentError.value(maxLength, 'maxLength', 'must be at least 1');
  }
  final chunks = <TtsChunk>[];
  final n = text.length;
  var start = 0;
  while (start < n) {
    final end =
        n - start <= maxLength ? n : _findBreak(text, start, start + maxLength);
    chunks.add(TtsChunk(
      index: chunks.length,
      start: start,
      end: end,
      text: text.substring(start, end),
    ));
    start = end;
  }
  return chunks;
}

/// Returns an end offset in (start, limit].
int _findBreak(String text, int start, int limit) {
  int? lastSentence;
  int? lastSoft;
  int? lastSpace;
  for (var i = start; i < limit; i++) {
    final c = text[i];
    if (_sentenceEnds.contains(c) || _softBreaks.contains(c)) {
      var j = i + 1;
      while (j < limit && _isSpace(text[j])) {
        j++;
      }
      if (_sentenceEnds.contains(c)) {
        lastSentence = j;
      } else {
        lastSoft = j;
      }
    } else if (_isSpace(c)) {
      lastSpace = i + 1;
    }
  }

  final minLength = maxLengthFloor(limit - start);
  final candidates = [lastSentence, lastSoft, lastSpace];
  // Prefer a good boundary that does not produce a tiny chunk.
  for (final c in candidates) {
    if (c != null && c - start >= minLength) return c;
  }
  // Otherwise any boundary at all.
  for (final c in candidates) {
    if (c != null) return c;
  }
  // No boundary: hard cut, without splitting a surrogate pair.
  var cut = limit;
  if (cut - start > 1) {
    final unit = text.codeUnitAt(cut - 1);
    if (unit >= 0xD800 && unit <= 0xDBFF) cut--;
  }
  return cut;
}

/// A boundary shorter than a third of the window is considered "too early".
int maxLengthFloor(int window) => window ~/ 3 < 1 ? 1 : window ~/ 3;
