import '../../bookmarks/domain/bookmark.dart';
import '../../bookmarks/domain/bookmark_store.dart' show randomId;
import 'chat_models.dart';

class ConversationNotFound implements Exception {
  const ConversationNotFound(this.id);

  final String id;

  @override
  String toString() => 'ConversationNotFound: $id';
}

/// Local chat history. Nothing here talks to a server.
abstract class ChatStore {
  /// A saint scope needs [saintId]; a section scope needs both ids.
  Future<Conversation> createConversation({
    ChatScopeKind scope = ChatScopeKind.book,
    String? saintId,
    String? sectionId,
  });

  /// Most recently updated first (ties: newest id first).
  Future<List<Conversation>> conversations();

  Future<Conversation?> conversation(String id);

  /// In conversation order (oldest first).
  Future<List<ChatMessage>> messages(String conversationId);

  /// Appends a message and bumps the conversation's update time. The first
  /// user message of an untitled conversation sets its title. Throws
  /// [ConversationNotFound] for an unknown conversation.
  Future<ChatMessage> addMessage({
    required String conversationId,
    required ChatRole role,
    required String content,
    MessageStatus status = MessageStatus.sent,
    String? metaJson,
  });

  /// Changes a message (for example pending -> sent or failed). Returns
  /// whether the message existed. Does not change the conversation order.
  Future<bool> updateMessage(
    String messageId, {
    String? content,
    MessageStatus? status,
    String? metaJson,
  });

  /// Deletes the conversation and all its messages. Returns whether it
  /// existed.
  Future<bool> deleteConversation(String id);

  /// Deletes all conversations and messages; returns how many conversations.
  Future<int> clearAll();
}

void checkScope(ChatScopeKind scope, String? saintId, String? sectionId) {
  if (scope == ChatScopeKind.book && (saintId != null || sectionId != null)) {
    throw ArgumentError('A book-scope conversation has no saint or section.');
  }
  if (scope == ChatScopeKind.saint && (saintId == null || sectionId != null)) {
    throw ArgumentError('A saint-scope conversation needs only a saint id.');
  }
  if (scope == ChatScopeKind.section &&
      (saintId == null || sectionId == null)) {
    throw ArgumentError('A section-scope conversation needs both ids.');
  }
}

int compareConversationsRecentFirst(Conversation a, Conversation b) {
  final c = b.updatedAt.compareTo(a.updatedAt);
  return c != 0 ? c : b.id.compareTo(a.id);
}

/// Memory-only store: tests, and the default when no database is injected.
class InMemoryChatStore implements ChatStore {
  InMemoryChatStore({IdGenerator? newId, Clock? clock})
      : _newId = newId,
        _clock = clock ?? DateTime.now;

  final IdGenerator? _newId;
  final Clock _clock;
  final Map<String, Conversation> _conversations = {};
  final Map<String, List<ChatMessage>> _messages = {};

  String _id(String prefix) => _newId?.call() ?? randomId(prefix);

  DateTime _now() => DateTime.fromMillisecondsSinceEpoch(
      _clock().millisecondsSinceEpoch,
      isUtc: true);

  @override
  Future<Conversation> createConversation({
    ChatScopeKind scope = ChatScopeKind.book,
    String? saintId,
    String? sectionId,
  }) async {
    checkScope(scope, saintId, sectionId);
    final now = _now();
    final c = Conversation(
      id: _id('conv'),
      title: '',
      scope: scope,
      saintId: saintId,
      sectionId: sectionId,
      createdAt: now,
      updatedAt: now,
    );
    _conversations[c.id] = c;
    _messages[c.id] = [];
    return c;
  }

  @override
  Future<List<Conversation>> conversations() async =>
      _conversations.values.toList()..sort(compareConversationsRecentFirst);

  @override
  Future<Conversation?> conversation(String id) async => _conversations[id];

  @override
  Future<List<ChatMessage>> messages(String conversationId) async =>
      [...?_messages[conversationId]];

  @override
  Future<ChatMessage> addMessage({
    required String conversationId,
    required ChatRole role,
    required String content,
    MessageStatus status = MessageStatus.sent,
    String? metaJson,
  }) async {
    final c = _conversations[conversationId];
    if (c == null) throw ConversationNotFound(conversationId);
    final list = _messages[conversationId]!;
    final now = _now();
    final m = ChatMessage(
      id: _id('msg'),
      conversationId: conversationId,
      seq: list.length + 1,
      role: role,
      content: content,
      status: status,
      createdAt: now,
      metaJson: metaJson,
    );
    list.add(m);
    _conversations[conversationId] = Conversation(
      id: c.id,
      title: c.title.isEmpty && role == ChatRole.user
          ? deriveTitle(content)
          : c.title,
      scope: c.scope,
      saintId: c.saintId,
      sectionId: c.sectionId,
      createdAt: c.createdAt,
      updatedAt: now,
    );
    return m;
  }

  @override
  Future<bool> updateMessage(
    String messageId, {
    String? content,
    MessageStatus? status,
    String? metaJson,
  }) async {
    for (final list in _messages.values) {
      for (var i = 0; i < list.length; i++) {
        final m = list[i];
        if (m.id != messageId) continue;
        list[i] = ChatMessage(
          id: m.id,
          conversationId: m.conversationId,
          seq: m.seq,
          role: m.role,
          content: content ?? m.content,
          status: status ?? m.status,
          createdAt: m.createdAt,
          metaJson: metaJson ?? m.metaJson,
        );
        return true;
      }
    }
    return false;
  }

  @override
  Future<bool> deleteConversation(String id) async {
    _messages.remove(id);
    return _conversations.remove(id) != null;
  }

  @override
  Future<int> clearAll() async {
    final n = _conversations.length;
    _conversations.clear();
    _messages.clear();
    return n;
  }
}
