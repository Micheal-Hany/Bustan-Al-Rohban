import 'package:bustan_al_rohban/features/ai_chat/domain/chat_models.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_store.dart';
import 'package:bustan_al_rohban/features/ai_chat/presentation/chat_history_cubit.dart';
import 'package:bustan_al_rohban/features/ai_chat/presentation/conversation_cubit.dart';
import 'package:bustan_al_rohban/features/library/presentation/load_status.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_test_support.dart';

void main() {
  group('ChatHistoryCubit', () {
    test('empty store -> empty status', () async {
      final cubit = ChatHistoryCubit(InMemoryChatStore());
      await cubit.load();
      expect(cubit.state.status, LoadStatus.empty);
      await cubit.close();
    });

    test('lists conversations, most recent first', () async {
      final store = InMemoryChatStore();
      final ids = await seedTwo(store);
      final cubit = ChatHistoryCubit(store);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.loaded);
      expect(cubit.state.conversations.map((c) => c.id),
          [ids.newer, ids.older]);
      await cubit.close();
    });

    test('delete removes one; deleting the last gives the empty state',
        () async {
      final store = InMemoryChatStore();
      final ids = await seedTwo(store);
      final cubit = ChatHistoryCubit(store);
      await cubit.load();
      await cubit.delete(ids.newer);
      expect(cubit.state.conversations.map((c) => c.id), [ids.older]);
      await cubit.delete(ids.older);
      expect(cubit.state.status, LoadStatus.empty);
      await cubit.close();
    });

    test('clearAll empties everything', () async {
      final store = InMemoryChatStore();
      await seedTwo(store);
      final cubit = ChatHistoryCubit(store);
      await cubit.load();
      await cubit.clearAll();
      expect(cubit.state.status, LoadStatus.empty);
      expect(await store.conversations(), isEmpty);
      await cubit.close();
    });

    test('create adds an empty conversation and returns its id', () async {
      final store = InMemoryChatStore();
      final cubit = ChatHistoryCubit(store);
      final id = await cubit.create();
      expect(cubit.state.conversations.single.id, id);
      await cubit.close();
    });

    test('a failing read gives an error state, retry recovers', () async {
      final store = FailingChatStore(InMemoryChatStore());
      await seedTwo(store);
      final cubit = ChatHistoryCubit(store);
      store.failReads = true;
      await cubit.load();
      expect(cubit.state.status, LoadStatus.error);
      store.failReads = false;
      await cubit.load();
      expect(cubit.state.status, LoadStatus.loaded);
      await cubit.close();
    });

    test('a failing delete keeps the list and reports the error', () async {
      final store = FailingChatStore(InMemoryChatStore());
      final ids = await seedTwo(store);
      final cubit = ChatHistoryCubit(store);
      await cubit.load();
      store.failWrites = true;
      await cubit.delete(ids.older);
      expect(cubit.state.conversations, hasLength(2));
      expect(cubit.state.error, isNotNull);
      await cubit.close();
    });
  });

  group('ConversationCubit', () {
    test('loads messages in order', () async {
      final store = InMemoryChatStore();
      final ids = await seedTwo(store);
      final cubit = ConversationCubit(store, ids.older);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.loaded);
      expect(cubit.state.messages.map((m) => m.content),
          ['سؤال قديم', 'جواب قديم']);
      await cubit.close();
    });

    test('a conversation without messages is empty', () async {
      final store = InMemoryChatStore();
      final c = await store.createConversation();
      final cubit = ConversationCubit(store, c.id);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.empty);
      await cubit.close();
    });

    test('an unknown conversation is an error', () async {
      final cubit = ConversationCubit(InMemoryChatStore(), 'nope');
      await cubit.load();
      expect(cubit.state.status, LoadStatus.error);
      await cubit.close();
    });

    test('the test exchange stores a user message and a FAKE reply and sets '
        'the title', () async {
      final store = InMemoryChatStore();
      final c = await store.createConversation();
      final cubit = ConversationCubit(store, c.id);
      await cubit.load();
      await cubit.addTestExchange('  ما هي الطاعة؟ ');
      expect(cubit.state.messages.map((m) => m.role),
          [ChatRole.user, ChatRole.assistant]);
      expect(cubit.state.messages.first.content, 'ما هي الطاعة؟');
      expect(cubit.state.conversation!.title, 'ما هي الطاعة؟');
      await cubit.close();
    });

    test('blank input stores nothing', () async {
      final store = InMemoryChatStore();
      final c = await store.createConversation();
      final cubit = ConversationCubit(store, c.id);
      await cubit.load();
      await cubit.addTestExchange('   ');
      expect(await store.messages(c.id), isEmpty);
      await cubit.close();
    });

    test('a failing write keeps what is shown and reports the error',
        () async {
      final store = FailingChatStore(InMemoryChatStore());
      final ids = await seedTwo(store);
      final cubit = ConversationCubit(store, ids.older);
      await cubit.load();
      store.failWrites = true;
      await cubit.addTestExchange('x');
      expect(cubit.state.messages, hasLength(2));
      expect(cubit.state.error, isNotNull);
      await cubit.close();
    });
  });
}
