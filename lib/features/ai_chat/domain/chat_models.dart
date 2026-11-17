enum ChatRole { user, assistant }

/// Delivery state of a message. A user message is `pending` while it is being
/// sent and becomes `sent` or `failed`; assistant messages are stored `sent`.
enum MessageStatus { sent, pending, failed }

/// How far the assistant may look (SPEC 7.5): the whole book, one saint, or
/// one section of a saint.
enum ChatScopeKind { book, saint, section }

class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.scope,
    required this.saintId,
    required this.sectionId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// Derived locally from the first user message; empty until there is one.
  final String title;
  final ChatScopeKind scope;
  final String? saintId;
  final String? sectionId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.seq,
    required this.role,
    required this.content,
    required this.status,
    required this.createdAt,
    this.metaJson,
  });

  final String id;
  final String conversationId;

  /// 1-based position inside the conversation. The order of messages.
  final int seq;
  final ChatRole role;
  final String content;
  final MessageStatus status;
  final DateTime createdAt;

  /// Free JSON for later features (for example answer citations, Task 11).
  final String? metaJson;
}

/// Maximum length of a derived title, in characters (runes).
const chatTitleMaxLength = 40;

/// Title from the first user question: whitespace collapsed, cut at a word
/// boundary when possible, with an ellipsis when shortened. No AI call.
String deriveTitle(String text, {int maxLength = chatTitleMaxLength}) {
  final collapsed = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  final runes = collapsed.runes.toList();
  if (runes.length <= maxLength) return collapsed;
  var cut = maxLength;
  // Prefer a word boundary in the last quarter of the allowed length.
  final floor = maxLength - maxLength ~/ 4;
  for (var i = maxLength; i >= floor; i--) {
    if (runes[i] == 0x20) {
      cut = i;
      break;
    }
  }
  return '${String.fromCharCodes(runes.sublist(0, cut)).trimRight()}…';
}
