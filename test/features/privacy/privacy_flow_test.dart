import 'package:bustan_al_rohban/app/app.dart';
import 'package:bustan_al_rohban/app/strings.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_notice_store.dart';
import 'package:bustan_al_rohban/features/privacy/domain/privacy_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/ai_chat/history/chat_test_support.dart';
import '../library/library_test_support.dart';

Future<void> _pump(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  group('privacy notice', () {
    testWidgets('is reachable from Settings and shows every section',
        (tester) async {
      await _pump(tester, const BustanApp());
      await tester.tap(find.byKey(const Key('nav-settings')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('settings-privacy')));
      await tester.tap(find.byKey(const Key('settings-privacy')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('privacy-screen')), findsOneWidget);
      for (final s in privacySections) {
        expect(find.byKey(Key('privacy-title-${s.id}')), findsOneWidget,
            reason: s.id);
      }
    });

    testWidgets('is reachable from the chat list', (tester) async {
      await _pump(tester, BustanApp(
              chatApi: FakeChatApi(),
              libraryRepository: repoFor(probeFor(twoSaintBook()))));
      await tester.tap(find.byKey(const Key('nav-chat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-privacy-link')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('privacy-screen')), findsOneWidget);
    });

    test('covers local data, history, what is sent, server, provider, '
        'reports, and what is not done', () {
      final ids = privacySections.map((s) => s.id).toSet();
      expect(ids, containsAll([
        'local', 'history', 'sending', 'server', 'provider', 'integrity',
        'report', 'none', 'limits',
      ]));
      final all = privacySections.map((s) => s.body).join(' ');
      expect(all, contains('النسخ الاحتياطي'));
      expect(all, contains('HTTPS'));
      expect(all, contains('OpenAI'));
      expect(all, contains('Gemini'));
      expect(all, contains('لا يحفظ الخادم'));
      expect(all, contains('لا تُستخدم لتدريب'));
    });

    testWidgets('the contact line is hidden until the owner supplies one',
        (tester) async {
      await _pump(tester, const BustanApp());
      await tester.tap(find.byKey(const Key('nav-settings')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('settings-privacy')));
      await tester.tap(find.byKey(const Key('settings-privacy')));
      await tester.pumpAndSettle();
      expect(privacyContact, isEmpty);
      expect(find.byKey(const Key('privacy-contact')), findsNothing);
    });
  });

  group('first-send notice', () {
    Future<void> openNewConversation(WidgetTester tester, Widget app) async {
      await _pump(tester, app);
      await tester.tap(find.byKey(const Key('nav-chat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-new')));
      await tester.pumpAndSettle();
    }

    Future<void> tapSend(WidgetTester tester, String text) async {
      await tester.enterText(find.byKey(const Key('chat-input')), text);
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
    }

    testWidgets('is shown before the first question and sends nothing '
        'until accepted', (tester) async {
      final api = FakeChatApi();
      final notice = InMemoryChatNoticeStore();
      await openNewConversation(
          tester, BustanApp(
              chatApi: api,
              libraryRepository: repoFor(probeFor(twoSaintBook())),
              chatNoticeStore: notice));
      await tapSend(tester, 'سؤال');
      expect(find.byKey(const Key('chat-notice-dialog')), findsOneWidget);
      expect(api.requests, isEmpty);

      await tester.tap(find.byKey(const Key('chat-notice-accept')));
      await tester.pumpAndSettle();
      expect(api.requests, hasLength(1));
      expect(await notice.accepted(), isTrue);
    });

    testWidgets('declining sends nothing, keeps the text, and asks again',
        (tester) async {
      final api = FakeChatApi();
      await openNewConversation(tester,
          BustanApp(
              chatApi: api,
              libraryRepository: repoFor(probeFor(twoSaintBook())),
              chatNoticeStore: InMemoryChatNoticeStore()));
      await tapSend(tester, 'سؤال');
      await tester.tap(find.byKey(const Key('chat-notice-cancel')));
      await tester.pumpAndSettle();
      expect(api.requests, isEmpty);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat-input')))
            .controller!
            .text,
        'سؤال',
      );
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-notice-dialog')), findsOneWidget);
    });

    testWidgets('is not shown again once accepted', (tester) async {
      final api = FakeChatApi();
      await openNewConversation(
        tester,
        BustanApp(
            chatApi: api,
            libraryRepository: repoFor(probeFor(twoSaintBook())),
            chatNoticeStore: InMemoryChatNoticeStore(accepted: true)),
      );
      await tapSend(tester, 'سؤال');
      expect(find.byKey(const Key('chat-notice-dialog')), findsNothing);
      expect(api.requests, hasLength(1));
    });

    testWidgets('can open the full privacy notice from the dialog',
        (tester) async {
      await openNewConversation(
        tester,
        BustanApp(
            chatApi: FakeChatApi(), chatNoticeStore: InMemoryChatNoticeStore()),
      );
      await tapSend(tester, 'سؤال');
      await tester.tap(find.byKey(const Key('chat-notice-read-more')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('privacy-screen')), findsOneWidget);
      expect(find.text(AppStrings.privacyTitle), findsWidgets);
    });
  });
}
