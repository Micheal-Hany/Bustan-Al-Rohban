import 'chat_api.dart';
import 'chat_models.dart';

/// Bounds for the conversation context sent with a new question (SPEC 7.4:
/// never the whole history blindly). They also stay inside the backend limits
/// (20 messages, 2000 characters each, 8000 in total).
class ContextLimits {
  const ContextLimits({
    this.maxMessages = 7,
    this.maxHistoryChars = 3000,
    this.userChars = 1000,
    this.assistantChars = 500,
    this.questionChars = 2000,
  });

  /// Including the new question.
  final int maxMessages;
  final int maxHistoryChars;
  final int userChars;
  final int assistantChars;
  final int questionChars;
}

String _cut(String s, int max) {
  final runes = s.trim().runes.toList();
  return runes.length <= max ? s.trim() : String.fromCharCodes(runes.take(max));
}

/// The messages to send: the most recent delivered turns that fit the budget
/// (oldest dropped first), then the new question. The scope is NOT part of
/// this: it always comes from the conversation record.
List<RequestMessage> buildContext(
  List<ChatMessage> history,
  String question, {
  ContextLimits limits = const ContextLimits(),
}) {
  final picked = <RequestMessage>[];
  var chars = 0;
  for (final m in history.reversed) {
    if (picked.length >= limits.maxMessages - 1) break;
    if (m.status != MessageStatus.sent) continue;
    final text = _cut(
      m.content,
      m.role == ChatRole.user ? limits.userChars : limits.assistantChars,
    );
    if (text.isEmpty) continue;
    if (chars + text.length > limits.maxHistoryChars) break;
    chars += text.length;
    picked.add(RequestMessage(m.role.name, text));
  }
  return [
    ...picked.reversed,
    RequestMessage('user', _cut(question, limits.questionChars)),
  ];
}
