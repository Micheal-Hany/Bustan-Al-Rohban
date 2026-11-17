import 'package:bustan_al_rohban/app/app.dart';
import 'package:bustan_al_rohban/app/strings.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_test_support.dart';

Future<void> _openChat(WidgetTester tester, ChatStore store) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BustanApp(chatStore: store));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-chat')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no conversations: empty state, privacy note, nothing to clear',
      (tester) async {
    await _openChat(tester, InMemoryChatStore());
    expect(find.byKey(const Key('chat-screen')), findsOneWidget);
    expect(find.text(AppStrings.chatEmpty), findsOneWidget);
    expect(find.byKey(const Key('chat-privacy-note')), findsOneWidget);
    expect(find.byKey(const Key('chat-clear-all')), findsNothing);
  });

  testWidgets('conversations are listed most recent first with title and '
      'scope', (tester) async {
    final store = InMemoryChatStore();
    final ids = await seedTwo(store);
    await _openChat(tester, store);
    final newer = find.byKey(Key('conversation-${ids.newer}'));
    final older = find.byKey(Key('conversation-${ids.older}'));
    expect(newer, findsOneWidget);
    expect(older, findsOneWidget);
    expect(tester.getTopLeft(newer).dy, lessThan(tester.getTopLeft(older).dy));
    expect(find.text('سؤال جديد'), findsOneWidget);
    expect(find.text(AppStrings.chatScopeSaint), findsOneWidget);
    expect(find.text(AppStrings.chatScopeBook), findsOneWidget);
  });

  testWidgets('opening a conversation shows its messages in order, and '
      'back returns', (tester) async {
    final store = InMemoryChatStore();
    final ids = await seedTwo(store);
    await _openChat(tester, store);
    await tester.tap(find.byKey(Key('conversation-${ids.older}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conversation-screen')), findsOneWidget);
    final q = find.text('سؤال قديم');
    final a = find.text('جواب قديم');
    expect(q, findsOneWidget);
    expect(a, findsOneWidget);
    expect(tester.getTopLeft(q).dy, lessThan(tester.getTopLeft(a).dy));

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-screen')), findsOneWidget);
  });

  testWidgets('delete removes one conversation', (tester) async {
    final store = InMemoryChatStore();
    final ids = await seedTwo(store);
    await _openChat(tester, store);
    await tester.tap(find.byKey(Key('conversation-delete-${ids.newer}')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('conversation-${ids.newer}')), findsNothing);
    expect(find.byKey(Key('conversation-${ids.older}')), findsOneWidget);
    expect((await store.conversations()).length, 1);
  });

  testWidgets('clear all asks first; cancel keeps, confirm deletes',
      (tester) async {
    final store = InMemoryChatStore();
    await seedTwo(store);
    await _openChat(tester, store);

    await tester.tap(find.byKey(const Key('chat-clear-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-clear-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-clear-cancel')));
    await tester.pumpAndSettle();
    expect((await store.conversations()).length, 2);

    await tester.tap(find.byKey(const Key('chat-clear-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-clear-confirm')));
    await tester.pumpAndSettle();
    expect(await store.conversations(), isEmpty);
    expect(find.text(AppStrings.chatEmpty), findsOneWidget);
  });

  testWidgets('create, add test messages, go back: the list shows the title '
      'and the messages persist', (tester) async {
    final store = InMemoryChatStore();
    await _openChat(tester, store);
    await tester.tap(find.byKey(const Key('chat-new-debug')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conversation-screen')), findsOneWidget);
    expect(find.text(AppStrings.chatEmptyConversation), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('chat-test-input')), 'ما هي المحبة؟');
    await tester.tap(find.byKey(const Key('chat-test-send')));
    await tester.pumpAndSettle();
    expect(find.text('ما هي المحبة؟'), findsWidgets);
    expect(find.text(AppStrings.chatTestReply), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('ما هي المحبة؟'), findsOneWidget); // the list title

    final c = (await store.conversations()).single;
    expect((await store.messages(c.id)).length, 2);

    // Reopen and continue.
    await tester.tap(find.byKey(Key('conversation-${c.id}')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('chat-test-input')), 'سؤال ثان');
    await tester.tap(find.byKey(const Key('chat-test-send')));
    await tester.pumpAndSettle();
    expect((await store.messages(c.id)).length, 4);
  });

  testWidgets('a failing store shows an error with retry', (tester) async {
    final store = FailingChatStore(InMemoryChatStore())..failReads = true;
    await _openChat(tester, store);
    expect(find.byKey(const Key('error-view')), findsOneWidget);
    store.failReads = false;
    await tester.tap(find.byKey(const Key('retry-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('empty-view')), findsOneWidget);
  });

  testWidgets('history is readable without any network (no network code is '
      'involved)', (tester) async {
    final store = InMemoryChatStore();
    final ids = await seedTwo(store);
    await _openChat(tester, store);
    await tester.tap(find.byKey(Key('conversation-${ids.older}')));
    await tester.pumpAndSettle();
    expect(find.text('جواب قديم'), findsOneWidget);
  });
}
