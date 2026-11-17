import 'package:bustan_al_rohban/features/ai_chat/domain/chat_models.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_store.dart';
import 'package:bustan_al_rohban/features/bookmarks/domain/bookmark.dart';
import 'package:flutter_test/flutter_test.dart';

/// Behaviour every [ChatStore] must have; run against the in-memory store and
/// the Drift store so the fake cannot drift from the real one.
void runChatStoreContract(
  String label,
  Future<ChatStore> Function(IdGenerator newId, Clock clock) create, {
  Object? skip,
}) {
  group('ChatStore contract: $label', skip: skip, () {
    late int n;
    late DateTime t;
    String newId() => 'id-${(++n).toString().padLeft(4, '0')}';
    DateTime clock() {
      t = t.add(const Duration(seconds: 1));
      return t;
    }

    late ChatStore store;

    setUp(() async {
      n = 0;
      t = DateTime.utc(2026, 1, 1);
      store = await create(newId, clock);
    });

    Future<ChatMessage> user(String cid, String text) => store.addMessage(
        conversationId: cid, role: ChatRole.user, content: text);
    Future<ChatMessage> bot(String cid, String text) => store.addMessage(
        conversationId: cid, role: ChatRole.assistant, content: text);

    test('starts empty', () async {
      expect(await store.conversations(), isEmpty);
    });

    test('creates a conversation with a stable id and no title yet', () async {
      final c = await store.createConversation();
      expect(c.id, isNotEmpty);
      expect(c.title, '');
      expect(c.scope, ChatScopeKind.book);
      expect(c.saintId, isNull);
      expect(c.createdAt, c.updatedAt);
      expect(c.createdAt.isUtc, isTrue);
      final read = await store.conversation(c.id);
      expect(read?.id, c.id);
      expect(await store.conversation('missing'), isNull);
    });

    test('ids are unique', () async {
      final a = await store.createConversation();
      final b = await store.createConversation();
      expect(a.id, isNot(b.id));
    });

    test('scope is stored and validated', () async {
      final s = await store.createConversation(
          scope: ChatScopeKind.saint, saintId: 'saint-a');
      expect(s.scope, ChatScopeKind.saint);
      expect((await store.conversation(s.id))!.saintId, 'saint-a');
      final sec = await store.createConversation(
          scope: ChatScopeKind.section,
          saintId: 'saint-a',
          sectionId: 'sec-a-001');
      final read = (await store.conversation(sec.id))!;
      expect(read.scope, ChatScopeKind.section);
      expect(read.sectionId, 'sec-a-001');

      expect(() => store.createConversation(scope: ChatScopeKind.saint),
          throwsArgumentError);
      expect(
          () => store.createConversation(
              scope: ChatScopeKind.section, saintId: 'saint-a'),
          throwsArgumentError);
      expect(() => store.createConversation(saintId: 'saint-a'),
          throwsArgumentError);
    });

    test('messages keep their order with roles, content and status',
        () async {
      final c = await store.createConversation();
      final m1 = await user(c.id, 'سؤال');
      final m2 = await bot(c.id, 'جواب');
      final m3 = await store.addMessage(
        conversationId: c.id,
        role: ChatRole.user,
        content: 'متابعة',
        status: MessageStatus.pending,
        metaJson: '{"k":1}',
      );
      expect([m1.seq, m2.seq, m3.seq], [1, 2, 3]);
      final list = await store.messages(c.id);
      expect(list.map((m) => m.content), ['سؤال', 'جواب', 'متابعة']);
      expect(list.map((m) => m.role),
          [ChatRole.user, ChatRole.assistant, ChatRole.user]);
      expect(list.map((m) => m.status),
          [MessageStatus.sent, MessageStatus.sent, MessageStatus.pending]);
      expect(list.last.metaJson, '{"k":1}');
      expect(list.first.metaJson, isNull);
      expect(list.every((m) => m.conversationId == c.id), isTrue);
    });

    test('Arabic and multi-line text is stored exactly', () async {
      final c = await store.createConversation();
      const text = 'بِسْمِ اللهِ\nسطر ثانٍ 😀 ‏';
      await user(c.id, text);
      expect((await store.messages(c.id)).single.content, text);
    });

    test('messages of different conversations stay apart', () async {
      final a = await store.createConversation();
      final b = await store.createConversation();
      await user(a.id, 'a1');
      await user(b.id, 'b1');
      await user(a.id, 'a2');
      expect((await store.messages(a.id)).map((m) => m.content), ['a1', 'a2']);
      expect((await store.messages(b.id)).map((m) => m.content), ['b1']);
      expect((await store.messages(b.id)).single.seq, 1);
    });

    test('adding to an unknown conversation fails', () async {
      expect(() => user('nope', 'x'), throwsA(isA<ConversationNotFound>()));
    });

    test('the title comes from the first user message only', () async {
      final c = await store.createConversation();
      await bot(c.id, 'مرحبا');
      expect((await store.conversation(c.id))!.title, '');
      await user(c.id, '  ما   معنى\nالصلاة؟ ');
      expect((await store.conversation(c.id))!.title, 'ما معنى الصلاة؟');
      await user(c.id, 'سؤال آخر');
      expect((await store.conversation(c.id))!.title, 'ما معنى الصلاة؟');
    });

    test('a long first question gives a truncated title', () async {
      final c = await store.createConversation();
      await user(c.id, 'كلمة ' * 30);
      final title = (await store.conversation(c.id))!.title;
      expect(title.endsWith('…'), isTrue);
      expect(title.runes.length, lessThanOrEqualTo(chatTitleMaxLength + 1));
    });

    test('conversations are listed most recently updated first', () async {
      final a = await store.createConversation();
      final b = await store.createConversation();
      final c = await store.createConversation();
      expect((await store.conversations()).map((x) => x.id), [c.id, b.id, a.id]);
      await user(a.id, 'جديد'); // a is now the most recent
      expect((await store.conversations()).map((x) => x.id), [a.id, c.id, b.id]);
      expect((await store.conversation(a.id))!.updatedAt
          .isAfter((await store.conversation(a.id))!.createdAt), isTrue);
    });

    test('updating a message changes it without reordering conversations',
        () async {
      final a = await store.createConversation();
      final b = await store.createConversation();
      final m = await store.addMessage(
          conversationId: a.id,
          role: ChatRole.user,
          content: 'x',
          status: MessageStatus.pending);
      await user(b.id, 'y'); // b is newer
      final before = (await store.conversations()).map((x) => x.id).toList();
      expect(await store.updateMessage(m.id, status: MessageStatus.failed),
          isTrue);
      expect(await store.updateMessage(m.id, content: 'x2'), isTrue);
      final read = (await store.messages(a.id)).single;
      expect(read.status, MessageStatus.failed);
      expect(read.content, 'x2');
      expect(read.seq, 1);
      expect((await store.conversations()).map((x) => x.id), before);
      expect(await store.updateMessage('missing', content: 'z'), isFalse);
    });

    test('deleting a conversation removes it and its messages only',
        () async {
      final a = await store.createConversation();
      final b = await store.createConversation();
      await user(a.id, 'a1');
      await bot(a.id, 'a2');
      await user(b.id, 'b1');
      expect(await store.deleteConversation(a.id), isTrue);
      expect(await store.conversation(a.id), isNull);
      expect(await store.messages(a.id), isEmpty);
      expect((await store.messages(b.id)).length, 1);
      expect((await store.conversations()).map((x) => x.id), [b.id]);
      expect(await store.deleteConversation(a.id), isFalse);
    });

    test('a deleted conversation cannot be written to', () async {
      final a = await store.createConversation();
      await store.deleteConversation(a.id);
      expect(() => user(a.id, 'x'), throwsA(isA<ConversationNotFound>()));
    });

    test('clear all removes everything and reports the count', () async {
      final a = await store.createConversation();
      final b = await store.createConversation();
      await user(a.id, 'a1');
      await user(b.id, 'b1');
      expect(await store.clearAll(), 2);
      expect(await store.conversations(), isEmpty);
      expect(await store.messages(a.id), isEmpty);
      expect(await store.clearAll(), 0);
      // The store still works afterwards.
      final c = await store.createConversation();
      await user(c.id, 'again');
      expect((await store.messages(c.id)).single.seq, 1);
    });
  });
}
