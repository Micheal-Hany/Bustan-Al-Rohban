import '../../../core/content/content_models.dart';
import 'chunk_splitter.dart';

/// One utterance. Chunks never span paragraphs, so the spoken position is
/// always a single paragraph ID (stable, citable).
class SpeechSegment {
  const SpeechSegment({required this.paragraphId, required this.text});

  final String paragraphId;
  final String text;
}

/// Turns paragraphs, in order, into speakable segments. Whitespace-only
/// chunks are dropped; nothing else is skipped or reordered.
List<SpeechSegment> buildSpeechPlan(
  Iterable<Paragraph> paragraphs, {
  int maxLength = 300,
}) {
  final out = <SpeechSegment>[];
  for (final p in paragraphs) {
    for (final c in splitIntoChunks(p.text, maxLength: maxLength)) {
      if (c.isSpeakable) {
        out.add(SpeechSegment(paragraphId: p.id, text: c.text));
      }
    }
  }
  return out;
}
