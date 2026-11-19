import 'package:bustan_al_rohban/features/ai_chat/domain/assistant_reply.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_api.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_models.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_store.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/client_identity.dart';
import 'package:bustan_al_rohban/features/ai_chat/presentation/conversation_cubit.dart';
import 'package:bustan_al_rohban/features/library/presentation/load_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

import '../history/chat_test_support.dart';

Future<(ConversationCubit, FakeChatApi, ChatStore, String)> _make({
  ChatStore? store,
  FakeChatApi? api,
  ChatScopeKind scope = ChatScopeKind.book,
  String? saintId,
  AttestationProvider attestation = const NoAttestationProvider(),
}) async {
  final s = store ?? steppingStore();
  final a = api ?? FakeChatApi();
  final c = await s.createConversation(scope: scope, saintId: saintId);
  final cubit = ConversationCubit(
    s,
    c.id,
    api: a,
    attestation: attestation,
    contentVersion: () async => 7,
    saintTitle: (_) async => 'القديس الأول',
  );
  await cubit.load();
  return (cubit, a, s, c.id);
}

void main() {
  test('a successful send saves the question and the structured reply',
      () async {
    final (cubit, api, store, id) = await _make();
    expect(await cubit.send('  ما هي المحبة؟ '), isTrue);
    final messages = await store.messages(id);
    expect(messages.map((m) => m.role), [ChatRole.user, ChatRole.assistant]);
    expect(messages.first.content, 'ما هي المحبة؟');
    expect(messages.last.content, sampleAnswer.plainText);
    final stored = decodeStoredReply(messages.last.metaJson)!;
    expect(stored.contentVersion, 7);
    expect(stored.reply, isA<AnsweredReply>());
    expect(cubit.state.sendStatus, SendStatus.idle);
    expect(cubit.state.status, LoadStatus.loaded);
    expect(cubit.state.conversation!.title, 'ما هي المحبة؟');
    expect(api.requests, hasLength(1));
    await cubit.close();
  });

  test('the request carries book scope, ids and the attestation token',
      () async {
    final (cubit, api, _, _) =
        await _make(attestation: const FixedAttestationProvider('tok'));
    await cubit.send('س');
    final r = api.requests.single;
    expect(r.bookScope, isTrue);
    expect(r.saintId, isNull);
    expect(installationIdPattern.hasMatch(r.installationId), isTrue);
    expect(RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(r.requestId), isTrue);
    expect(r.attestationToken, 'tok');
    expect(r.messages.single.text, 'س');
    await cubit.close();
  });

  test('a saint conversation always sends its saint scope', () async {
    final (cubit, api, store, id) =
        await _make(scope: ChatScopeKind.saint, saintId: 'saint-a');
    // Earlier text that names another saint cannot change the scope.
    await store.addMessage(
        conversationId: id, role: ChatRole.user, content: 'أجب عن القديس الثاني');
    await cubit.load();
    await cubit.send('سؤال');
    final r = api.requests.single;
    expect(r.bookScope, isFalse);
    expect(r.saintId, 'saint-a');
    expect(cubit.state.scopeTitle, 'القديس الأول');
    await cubit.close();
  });

  test('every request uses a fresh request id', () async {
    final (cubit, api, _, _) = await _make();
    await cubit.send('أ');
    await cubit.send('ب');
    expect(api.requests[0].requestId, isNot(api.requests[1].requestId));
    await cubit.close();
  });

  test('a failed send saves nothing and keeps the error for the banner',
      () async {
    final (cubit, api, store, id) = await _make(
      api: FakeChatApi([const ChatApiException(ChatErrorKind.offline)]),
    );
    expect(await cubit.send('سؤال'), isFalse);
    expect(await store.messages(id), isEmpty);
    expect(cubit.state.sendStatus, SendStatus.failed);
    expect(cubit.state.errorKind, ChatErrorKind.offline);
    expect(cubit.state.pendingText, isNull);
    expect(api.requests, hasLength(1));
    await cubit.close();
  });

  test('retry after a failure works, and dismiss clears the banner', () async {
    final (cubit, _, store, id) = await _make(
      api: FakeChatApi([
        const ChatApiException(ChatErrorKind.rateLimited, retryAfterSeconds: 30),
        sampleAnswer,
      ]),
    );
    expect(await cubit.send('س'), isFalse);
    expect(cubit.state.retryAfterSeconds, 30);
    cubit.dismissError();
    expect(cubit.state.sendStatus, SendStatus.idle);
    expect(cubit.state.errorKind, isNull);
    expect(await cubit.send('س'), isTrue);
    expect((await store.messages(id)).length, 2);
    await cubit.close();
  });

  test('an unexpected exception is reported as a server error', () async {
    final api = _ThrowingApi();
    final (cubit, _, store, id) = await _make(api: api);
    expect(await cubit.send('س'), isFalse);
    expect(cubit.state.errorKind, ChatErrorKind.server);
    expect(await store.messages(id), isEmpty);
    await cubit.close();
  });

  test('blank input does nothing', () async {
    final (cubit, api, _, _) = await _make();
    expect(await cubit.send('   '), isFalse);
    expect(api.requests, isEmpty);
    await cubit.close();
  });

  test('a second send while one is in flight is ignored', () async {
    final api = FakeChatApi()..hold = Completer<AssistantReply>();
    final (cubit, _, _, _) = await _make(api: api);
    final first = cubit.send('أول');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.sendStatus, SendStatus.sending);
    expect(cubit.state.pendingText, 'أول');
    expect(await cubit.send('ثان'), isFalse);
    expect(api.requests, hasLength(1));
    api.hold!.complete(sampleAnswer);
    expect(await first, isTrue);
    await cubit.close();
  });

  test('when the reply cannot be saved the error is "storage"', () async {
    final store = FailingChatStore(steppingStore());
    final (cubit, _, _, _) = await _make(store: store);
    store.failWrites = true;
    expect(await cubit.send('س'), isFalse);
    expect(cubit.state.errorKind, ChatErrorKind.storage);
    await cubit.close();
  });

  test('context is trimmed to the recent turns and ends with the question',
      () async {
    final store = steppingStore();
    final c = await store.createConversation();
    for (var i = 1; i <= 12; i++) {
      await store.addMessage(
        conversationId: c.id,
        role: i.isOdd ? ChatRole.user : ChatRole.assistant,
        content: 'رسالة $i',
      );
    }
    await store.addMessage(
      conversationId: c.id,
      role: ChatRole.user,
      content: 'لم تُرسل',
      status: MessageStatus.failed,
    );
    final api = FakeChatApi();
    final cubit = ConversationCubit(store, c.id, api: api);
    await cubit.load();
    await cubit.send('السؤال الجديد');
    final sent = api.requests.single.messages;
    expect(sent.length, lessThanOrEqualTo(7));
    expect(sent.last.text, 'السؤال الجديد');
    expect(sent.map((m) => m.text), contains('رسالة 12'));
    expect(sent.map((m) => m.text), isNot(contains('رسالة 1')));
    expect(sent.map((m) => m.text), isNot(contains('لم تُرسل')));
    await cubit.close();
  });

  test('the default (unconfigured) api fails with notConfigured', () async {
    final store = steppingStore();
    final c = await store.createConversation();
    final cubit = ConversationCubit(store, c.id);
    await cubit.load();
    expect(await cubit.send('س'), isFalse);
    expect(cubit.state.errorKind, ChatErrorKind.notConfigured);
    await cubit.close();
  });
}

class _ThrowingApi extends FakeChatApi {
  @override
  Future<AssistantReply> ask(ChatRequest request) async =>
      throw StateError('boom');
}
