import 'package:bustan_al_rohban/features/ai_chat/domain/chat_models.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_store.dart';

/// A store that can be made to fail, wrapping a working one.
class FailingChatStore implements ChatStore {
  FailingChatStore(this.inner);

  final ChatStore inner;
  bool failReads = false;
  bool failWrites = false;

  void _r() {
    if (failReads) throw StateError('read failed');
  }

  void _w() {
    if (failWrites) throw StateError('write failed');
  }

  @override
  Future<Conversation> createConversation({
    ChatScopeKind scope = ChatScopeKind.book,
    String? saintId,
    String? sectionId,
  }) async {
    _w();
    return inner.createConversation(
        scope: scope, saintId: saintId, sectionId: sectionId);
  }

  @override
  Future<List<Conversation>> conversations() async {
    _r();
    return inner.conversations();
  }

  @override
  Future<Conversation?> conversation(String id) async {
    _r();
    return inner.conversation(id);
  }

  @override
  Future<List<ChatMessage>> messages(String conversationId) async {
    _r();
    return inner.messages(conversationId);
  }

  @override
  Future<ChatMessage> addMessage({
    required String conversationId,
    required ChatRole role,
    required String content,
    MessageStatus status = MessageStatus.sent,
    String? metaJson,
  }) async {
    _w();
    return inner.addMessage(
        conversationId: conversationId,
        role: role,
        content: content,
        status: status,
        metaJson: metaJson);
  }

  @override
  Future<bool> updateMessage(String messageId,
      {String? content, MessageStatus? status, String? metaJson}) async {
    _w();
    return inner.updateMessage(messageId,
        content: content, status: status, metaJson: metaJson);
  }

  @override
  Future<bool> deleteConversation(String id) async {
    _w();
    return inner.deleteConversation(id);
  }

  @override
  Future<int> clearAll() async {
    _w();
    return inner.clearAll();
  }
}

/// An in-memory store whose clock advances one second per call, so
/// "most recently updated" is deterministic.
InMemoryChatStore steppingStore() {
  var t = DateTime.utc(2026, 1, 1);
  return InMemoryChatStore(clock: () => t = t.add(const Duration(seconds: 1)));
}

/// Two conversations: the first created is older. Returns their ids.
Future<({String older, String newer})> seedTwo(ChatStore store) async {
  final a = await store.createConversation();
  await store.addMessage(
      conversationId: a.id, role: ChatRole.user, content: 'سؤال قديم');
  await store.addMessage(
      conversationId: a.id, role: ChatRole.assistant, content: 'جواب قديم');
  final b = await store.createConversation(
      scope: ChatScopeKind.saint, saintId: 'saint-a');
  await store.addMessage(
      conversationId: b.id, role: ChatRole.user, content: 'سؤال جديد');
  return (older: a.id, newer: b.id);
}
