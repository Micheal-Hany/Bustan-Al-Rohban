import 'dart:async';

import 'package:bustan_al_rohban/app/app.dart';
import 'package:bustan_al_rohban/app/strings.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/assistant_reply.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_api.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_models.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_store.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../library/library_test_support.dart';
import '../history/chat_test_support.dart';

Future<void> _boot(
  WidgetTester tester, {
  required ChatStore store,
  required ChatApi api,
  ReportSender? reports,
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BustanApp(
    chatStore: store,
    chatApi: api,
    reportSender: reports,
    libraryRepository: repoFor(probeFor(twoSaintBook())),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-chat')));
  await tester.pumpAndSettle();
}

/// Opens a brand-new book conversation from the chat list.
Future<void> _newConversation(
  WidgetTester tester, {
  ChatStore? store,
  ChatApi? api,
  ReportSender? reports,
}) async {
  await _boot(
    tester,
    store: store ?? steppingStore(),
    api: api ?? FakeChatApi(),
    reports: reports,
  );
  await tester.tap(find.byKey(const Key('chat-new')));
  await tester.pumpAndSettle();
}

Future<void> _ask(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('chat-input')), text);
  await tester.tap(find.byKey(const Key('chat-send')));
  await tester.pumpAndSettle();
}

String _inputText(WidgetTester tester) => tester
    .widget<TextField>(find.byKey(const Key('chat-input')))
    .controller!
    .text;

void main() {
  testWidgets('a new conversation shows the book-only indicator, the scope '
      'and the prompt', (tester) async {
    await _newConversation(tester);
    expect(find.byKey(const Key('conversation-screen')), findsOneWidget);
    expect(find.text(AppStrings.chatBookOnly), findsOneWidget);
    expect(find.byKey(const Key('scope-chip')), findsOneWidget);
    expect(find.textContaining(AppStrings.chatScopeBookFull), findsOneWidget);
    expect(find.text(AppStrings.chatAskPrompt), findsOneWidget);
  });

  testWidgets('layout is right-to-left', (tester) async {
    await _newConversation(tester);
    final ctx = tester.element(find.byKey(const Key('conversation-screen')));
    expect(Directionality.of(ctx), TextDirection.rtl);
  });

  testWidgets('an answer renders quotation and paraphrase differently, with '
      'source chips and the pastoral note; the input is cleared',
      (tester) async {
    final store = steppingStore();
    await _newConversation(tester, store: store);
    await _ask(tester, 'ما هي المحبة؟');
    expect(find.byKey(const Key('block-quotation')), findsOneWidget);
    expect(find.byKey(const Key('block-paraphrase')), findsOneWidget);
    expect(find.text(AppStrings.chatBlockQuotation), findsOneWidget);
    expect(find.text(AppStrings.chatBlockParaphrase), findsOneWidget);
    expect(find.text('نص الاقتباس من الكتاب'), findsOneWidget);
    // Chips are de-duplicated per block: one per block here.
    expect(find.byKey(const Key('ref-p-000001')), findsNWidgets(2));
    expect(find.textContaining('القديس الأول › قسم أ ١'), findsWidgets);
    expect(find.textContaining('ص 3'), findsWidgets);
    expect(find.byKey(const Key('pastoral-note')), findsOneWidget);
    expect(_inputText(tester), isEmpty);
    expect(find.byKey(const Key('sending-indicator')), findsNothing);
  });

  testWidgets('an inference block is labelled as not from the book',
      (tester) async {
    const reply = AnsweredReply(blocks: [
      AnswerBlock(
        type: BlockType.inference,
        text: 'استنتاج',
        references: [sampleRef],
      ),
    ]);
    await _newConversation(tester, api: FakeChatApi([reply]));
    await _ask(tester, 'س');
    expect(find.byKey(const Key('block-inference')), findsOneWidget);
    expect(find.text(AppStrings.chatBlockInference), findsOneWidget);
    expect(find.byKey(const Key('pastoral-note')), findsNothing);
  });

  testWidgets('while waiting: indicator shown and input disabled',
      (tester) async {
    final api = FakeChatApi()..hold = Completer<AssistantReply>();
    await _newConversation(tester, api: api);
    await tester.enterText(find.byKey(const Key('chat-input')), 'سؤال');
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('sending-indicator')), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byKey(const Key('chat-input'))).enabled,
      isFalse,
    );
    expect(find.text('سؤال'), findsWidgets); // the pending question is shown
    api.hold!.complete(sampleAnswer);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sending-indicator')), findsNothing);
    expect(find.byKey(const Key('block-quotation')), findsOneWidget);
  });

  testWidgets('offline: error shown, typed text kept, nothing saved, retry '
      'succeeds', (tester) async {
    final store = steppingStore();
    final api = FakeChatApi([
      const ChatApiException(ChatErrorKind.offline),
      sampleAnswer,
    ]);
    await _newConversation(tester, store: store, api: api);
    await _ask(tester, 'سؤال بلا إنترنت');
    expect(find.byKey(const Key('send-error-offline')), findsOneWidget);
    expect(find.text(AppStrings.chatErrOffline), findsOneWidget);
    expect(_inputText(tester), 'سؤال بلا إنترنت');
    final c = (await store.conversations()).single;
    expect(await store.messages(c.id), isEmpty);

    await tester.tap(find.byKey(const Key('send-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('send-error')), findsNothing);
    expect(find.byKey(const Key('block-quotation')), findsOneWidget);
    expect(_inputText(tester), isEmpty);
    expect((await store.messages(c.id)).length, 2);
  });

  testWidgets('the error banner can be dismissed', (tester) async {
    await _newConversation(
      tester,
      api: FakeChatApi([const ChatApiException(ChatErrorKind.server)]),
    );
    await _ask(tester, 'س');
    expect(find.byKey(const Key('send-error')), findsOneWidget);
    await tester.tap(find.byKey(const Key('send-error-dismiss')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('send-error')), findsNothing);
    expect(_inputText(tester), 'س');
  });

  for (final c in <(ChatErrorKind, String)>[
    (ChatErrorKind.timeout, AppStrings.chatErrTimeout),
    (ChatErrorKind.unavailable, AppStrings.chatErrUnavailable),
    (ChatErrorKind.attestation, AppStrings.chatErrAttestation),
    (ChatErrorKind.server, AppStrings.chatErrServer),
    (ChatErrorKind.badResponse, AppStrings.chatErrBadResponse),
    (ChatErrorKind.notConfigured, AppStrings.chatErrNotConfigured),
  ]) {
    testWidgets('error state: ${c.$1.name}', (tester) async {
      await _newConversation(
        tester,
        api: FakeChatApi([ChatApiException(c.$1)]),
      );
      await _ask(tester, 'س');
      expect(find.text(c.$2), findsOneWidget);
      // A missing configuration cannot be fixed by retrying.
      expect(find.byKey(const Key('send-retry')),
          c.$1 == ChatErrorKind.notConfigured ? findsNothing : findsOneWidget);
    });
  }

  testWidgets('rate limited: shows the wait time', (tester) async {
    await _newConversation(
      tester,
      api: FakeChatApi([
        const ChatApiException(ChatErrorKind.rateLimited, retryAfterSeconds: 90),
      ]),
    );
    await _ask(tester, 'س');
    expect(find.textContaining('90 ${AppStrings.chatSecondsWord}'),
        findsOneWidget);
  });

  testWidgets('a refusal shows the fixed message and no sources or report',
      (tester) async {
    await _newConversation(tester, api: FakeChatApi([sampleRefusal]));
    await _ask(tester, 'ما هي عاصمة فرنسا؟');
    expect(find.byKey(const Key('refused-message')), findsOneWidget);
    expect(find.text(sampleRefusal.message), findsWidgets);
    expect(find.byKey(const Key('refused-ask-book')), findsNothing);
    expect(find.byKey(const Key('block-quotation')), findsNothing);
    expect(find.textContaining(AppStrings.chatReportAnswer), findsNothing);
  });

  testWidgets('an out-of-scope refusal offers to ask the whole book in a new '
      'conversation', (tester) async {
    final store = steppingStore();
    final c = await store.createConversation(
        scope: ChatScopeKind.saint, saintId: 'saint-a');
    await _boot(tester, store: store, api: FakeChatApi([sampleOutOfScope]));
    await tester.tap(find.byKey(Key('conversation-${c.id}')));
    await tester.pumpAndSettle();
    expect(find.textContaining('القديس القديس الأول'), findsOneWidget);
    await _ask(tester, 'ماذا قال القديس الثاني؟');
    await tester.tap(find.byKey(const Key('refused-ask-book')));
    await tester.pumpAndSettle();
    final all = await store.conversations();
    expect(all.length, 2);
    expect(all.first.scope, ChatScopeKind.book); // newest first
    expect(find.textContaining(AppStrings.chatScopeBookFull), findsOneWidget);
    expect(find.byKey(const Key('empty-view')), findsOneWidget);
  });

  testWidgets('a safety reply is a distinct card without a report button',
      (tester) async {
    await _newConversation(tester, api: FakeChatApi([sampleSafety]));
    await _ask(tester, 'حللني من خطاياي');
    expect(find.byKey(const Key('safety-card')), findsOneWidget);
    expect(find.text(sampleSafety.message), findsWidgets);
    expect(find.textContaining(AppStrings.chatReportAnswer), findsNothing);
  });

  testWidgets('a stored conversation is readable with no network call',
      (tester) async {
    final store = steppingStore();
    final c = await store.createConversation();
    await store.addMessage(
        conversationId: c.id, role: ChatRole.user, content: 'سؤال محفوظ');
    await store.addMessage(
      conversationId: c.id,
      role: ChatRole.assistant,
      content: sampleAnswer.plainText,
      metaJson: encodeStoredReply(sampleAnswer, 1),
    );
    final api = FakeChatApi();
    await _boot(tester, store: store, api: api);
    await tester.tap(find.byKey(Key('conversation-${c.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('block-quotation')), findsOneWidget);
    expect(find.text('سؤال محفوظ'), findsWidgets);
    expect(api.requests, isEmpty);
  });

  testWidgets('an assistant message without structured data shows its plain '
      'text', (tester) async {
    final store = steppingStore();
    final c = await store.createConversation();
    await store.addMessage(
        conversationId: c.id, role: ChatRole.user, content: 'س');
    await store.addMessage(
        conversationId: c.id,
        role: ChatRole.assistant,
        content: 'نص عادي بلا بنية',
        metaJson: 'garbage');
    await _boot(tester, store: store, api: FakeChatApi());
    await tester.tap(find.byKey(Key('conversation-${c.id}')));
    await tester.pumpAndSettle();
    expect(find.text('نص عادي بلا بنية'), findsOneWidget);
  });

  testWidgets('tapping a source chip opens the reader at that paragraph',
      (tester) async {
    await _newConversation(tester);
    await _ask(tester, 'س');
    await tester.tap(find.byKey(const Key('ref-p-000001')).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reader-screen')), findsOneWidget);
  });

  testWidgets('scope change is explicit: the sheet explains it starts a new '
      'conversation, then opens one with the chosen saint', (tester) async {
    final store = steppingStore();
    await _newConversation(tester, store: store);
    final before = (await store.conversations()).single;
    await tester.tap(find.byKey(const Key('scope-change')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.chatScopeChangeNote), findsOneWidget);
    await tester.tap(find.byKey(const Key('scope-saint-saint-a')));
    await tester.pumpAndSettle();
    final all = await store.conversations();
    expect(all.length, 2);
    final created = all.firstWhere((c) => c.id != before.id);
    expect(created.scope, ChatScopeKind.saint);
    expect(created.saintId, 'saint-a');
    expect(before.scope, ChatScopeKind.book); // the old one is untouched
    expect(find.textContaining('القديس القديس الأول'), findsOneWidget);
  });

  group('report this answer', () {
    testWidgets('the confirmation screen shows exactly what will be sent',
        (tester) async {
      await _newConversation(tester);
      await _ask(tester, 'ما هي المحبة؟');
      await tester.tap(find.textContaining(AppStrings.chatReportAnswer));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('report-screen')), findsOneWidget);
      Text field(String key) =>
          tester.widget<Text>(find.byKey(Key(key)));
      expect(field('report-field-answer').data, sampleAnswer.plainText);
      expect(field('report-field-question').data, 'ما هي المحبة؟');
      expect(field('report-field-citations').data, 'p-000001');
      expect(RegExp(r'^\d+$').hasMatch(field('report-field-version').data!),
          isTrue);
      expect(field('report-field-model').data, 'fake / fake-1');
      expect(find.byKey(const Key('report-not-sent')), findsOneWidget);
    });

    testWidgets('send needs a reason; with no sender wired it says so and '
        'sends nothing', (tester) async {
      await _newConversation(tester);
      await _ask(tester, 'س');
      await tester.tap(find.textContaining(AppStrings.chatReportAnswer));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byKey(const Key('report-send'))).onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('report-reason-not_from_book')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('report-send')));
      await tester.tap(find.byKey(const Key('report-send')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.reportUnavailable), findsOneWidget);
    });

    testWidgets('a working sender receives the exact payload (no history)',
        (tester) async {
      final sender = _RecordingSender();
      await _newConversation(tester, reports: sender);
      await _ask(tester, 'ما هي المحبة؟');
      await tester.tap(find.textContaining(AppStrings.chatReportAnswer));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('report-reason-wrong_or_invented')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('report-note')), 'ملاحظة');
      await tester.ensureVisible(find.byKey(const Key('report-send')));
      await tester.tap(find.byKey(const Key('report-send')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.reportSentThanks), findsOneWidget);
      final json = sender.sent.single.toJson();
      expect(json['reason'], 'wrong_or_invented');
      expect(json['note'], 'ملاحظة');
      expect(json['question'], 'ما هي المحبة؟');
      expect(json['citedParagraphIds'], ['p-000001']);
      expect(json['provider'], 'fake');
      expect(json.keys.toSet(), {
        'reason', 'note', 'answerText', 'question', 'citedParagraphIds',
        'contentVersion', 'provider', 'model',
      });
    });
  });
}

class _RecordingSender implements ReportSender {
  final sent = <ReportPayload>[];

  @override
  Future<void> send(ReportPayload payload) async => sent.add(payload);
}
