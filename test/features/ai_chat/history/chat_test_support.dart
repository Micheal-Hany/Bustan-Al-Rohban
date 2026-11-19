import 'dart:async';

import 'package:bustan_al_rohban/features/ai_chat/domain/assistant_reply.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_api.dart';
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

// ---- Task 11: fake backend client and sample replies ----

/// Returns queued replies (or throws queued exceptions), records requests,
/// and can hold the next call open with [hold].
class FakeChatApi implements ChatApi {
  FakeChatApi([List<Object>? queue]) : queue = [...?queue];

  final List<Object> queue;
  final List<ChatRequest> requests = [];
  Completer<AssistantReply>? hold;

  @override
  Future<AssistantReply> ask(ChatRequest request) async {
    requests.add(request);
    final h = hold;
    if (h != null) return h.future;
    final next = queue.isEmpty ? sampleAnswer : queue.removeAt(0);
    if (next is ChatApiException) throw next;
    return next as AssistantReply;
  }
}

const sampleRef = SourceRef(
  paragraphId: 'p-000001',
  saintId: 'saint-a',
  saintTitle: 'القديس الأول',
  sectionId: 'sec-a-001',
  sectionTitle: 'قسم أ ١',
  page: 3,
);

const sampleAnswer = AnsweredReply(
  blocks: [
    AnswerBlock(
      type: BlockType.quotation,
      text: 'نص الاقتباس من الكتاب',
      references: [sampleRef],
    ),
    AnswerBlock(
      type: BlockType.paraphrase,
      text: 'تلخيص لما ورد',
      references: [sampleRef],
    ),
  ],
  pastoralNote: 'للقرارات الخاصة استشر أب اعترافك.',
  provider: 'fake',
  model: 'fake-1',
);

const sampleRefusal = RefusedReply(
  reason: 'insufficient_evidence',
  message: 'لم أجد في كتاب بستان الرهبان ما يجيب عن هذا السؤال.',
);

const sampleOutOfScope = RefusedReply(
  reason: 'out_of_scope_saint',
  message: 'لم أجد في كتاب بستان الرهبان ما يجيب عن هذا السؤال.',
  suggestedSaintIds: ['saint-b'],
);

const sampleSafety = SafetyReply(
  category: 'confession_sacrament',
  message: 'تحدث مع أب اعترافك.',
  referral: ['confession_father'],
);
