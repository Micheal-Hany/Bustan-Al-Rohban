import 'dart:convert';

import 'package:bustan_al_rohban/features/ai_chat/domain/assistant_reply.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_api.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_models.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/client_identity.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/context_window.dart';
import 'package:flutter_test/flutter_test.dart';

import '../history/chat_test_support.dart';

ChatMessage _msg(int seq, ChatRole role, String text,
        {MessageStatus status = MessageStatus.sent}) =>
    ChatMessage(
      id: 'm$seq',
      conversationId: 'c',
      seq: seq,
      role: role,
      content: text,
      status: status,
      createdAt: DateTime.utc(2026, 1, 1),
    );

void main() {
  group('AssistantReply parsing', () {
    test('answered reply with blocks, references and meta', () {
      final r = AssistantReply.fromJson({
        'status': 'answered',
        'blocks': [
          {
            'type': 'quotation',
            'text': 'نص',
            'citations': ['p-000001'],
            'references': [sampleRef.toJson()],
          },
        ],
        'pastoralNote': 'ملاحظة',
        'meta': {'provider': 'openai', 'model': 'm1', 'attempts': 1},
      }) as AnsweredReply;
      expect(r.blocks.single.type, BlockType.quotation);
      expect(r.blocks.single.references.single.page, 3);
      expect(r.pastoralNote, 'ملاحظة');
      expect(r.provider, 'openai');
      expect(r.citedParagraphIds, ['p-000001']);
    });

    test('refused and safety replies', () {
      final a = AssistantReply.fromJson({
        'status': 'refused',
        'reason': 'out_of_scope_saint',
        'message': 'م',
        'suggestedSaintIds': ['saint-b'],
      }) as RefusedReply;
      expect(a.suggestedSaintIds, ['saint-b']);
      final b = AssistantReply.fromJson({
        'status': 'safety',
        'category': 'self_harm',
        'message': 'م',
        'referral': ['emergency'],
      }) as SafetyReply;
      expect(b.referral, ['emergency']);
    });

    test('anything unexpected is a FormatException', () {
      for (final bad in <Map<String, dynamic>>[
        {'status': 'weird'},
        {'status': 'answered', 'blocks': []},
        {
          'status': 'answered',
          'blocks': [
            {'type': 'shout', 'text': 'x'}
          ]
        },
        {'status': 'refused', 'reason': 'r'},
      ]) {
        expect(() => AssistantReply.fromJson(bad), throwsFormatException);
      }
    });

    test('stored reply round-trips with the content version', () {
      final json = encodeStoredReply(sampleAnswer, 7);
      final back = decodeStoredReply(json)!;
      expect(back.contentVersion, 7);
      final r = back.reply as AnsweredReply;
      expect(r.blocks.length, 2);
      expect(r.plainText, sampleAnswer.plainText);
      expect(r.provider, 'fake');
    });

    test('missing or corrupt stored metadata gives null (plain text shown)',
        () {
      expect(decodeStoredReply(null), isNull);
      expect(decodeStoredReply('not json'), isNull);
      expect(decodeStoredReply(jsonEncode({'v': 2})), isNull);
    });
  });

  group('ChatRequest JSON (backend contract)', () {
    test('book scope has an empty scope object', () {
      final j = const ChatRequest(
        requestId: 'req-1',
        installationId: 'inst-0123456789abcdef',
        bookScope: true,
        messages: [RequestMessage('user', 'س')],
      ).toJson();
      expect(j['mode'], 'book_scope');
      expect(j['scope'], isEmpty);
      expect(j.containsKey('attestationToken'), isFalse);
    });

    test('saint scope carries saintId (and sectionId) and the token', () {
      final j = const ChatRequest(
        requestId: 'req-1',
        installationId: 'inst-0123456789abcdef',
        bookScope: false,
        saintId: 'saint-a',
        sectionId: 'sec-a-001',
        messages: [RequestMessage('user', 'س')],
        attestationToken: 'tok',
      ).toJson();
      expect(j['mode'], 'saint_scope');
      expect(j['scope'], {'saintId': 'saint-a', 'sectionId': 'sec-a-001'});
      expect(j['attestationToken'], 'tok');
    });
  });

  group('buildContext', () {
    test('ends with the new question and keeps the most recent turns', () {
      final history = [
        for (var i = 1; i <= 20; i++)
          _msg(i, i.isOdd ? ChatRole.user : ChatRole.assistant, 'رسالة $i'),
      ];
      final ctx = buildContext(history, '  سؤال جديد ');
      expect(ctx.length, 7); // 6 recent + the question
      expect(ctx.last.text, 'سؤال جديد');
      expect(ctx.last.role, 'user');
      expect(ctx[ctx.length - 2].text, 'رسالة 20'); // newest history kept
      expect(ctx.first.text, 'رسالة 15'); // oldest dropped
    });

    test('skips pending and failed messages', () {
      final ctx = buildContext([
        _msg(1, ChatRole.user, 'أ'),
        _msg(2, ChatRole.user, 'فاشلة', status: MessageStatus.failed),
        _msg(3, ChatRole.user, 'معلقة', status: MessageStatus.pending),
      ], 'س');
      expect(ctx.map((m) => m.text), ['أ', 'س']);
    });

    test('respects the character budget and per-message caps', () {
      final long = 'ا' * 900;
      final history = [
        _msg(1, ChatRole.user, long),
        _msg(2, ChatRole.assistant, long), // capped to 500
        _msg(3, ChatRole.user, long),
        _msg(4, ChatRole.assistant, long),
        _msg(5, ChatRole.user, long),
      ];
      final ctx = buildContext(history, 'س');
      final historyChars =
          ctx.take(ctx.length - 1).fold<int>(0, (n, m) => n + m.text.length);
      expect(historyChars, lessThanOrEqualTo(3000));
      expect(ctx.where((m) => m.role == 'assistant').every((m) => m.text.length <= 500), isTrue);
      expect(ctx.last.text, 'س');
    });

    test('a very long question is cut to the backend limit', () {
      final ctx = buildContext(const [], 'ب' * 5000);
      expect(ctx.single.text.length, 2000);
    });

    test('with no history the context is just the question', () {
      expect(buildContext(const [], 'س').single.text, 'س');
    });
  });

  group('client identity', () {
    test('installation ids match the backend pattern and differ', () {
      final a = newInstallationId();
      final b = newInstallationId();
      expect(installationIdPattern.hasMatch(a), isTrue);
      expect(a, isNot(b));
    });

    test('the in-memory store keeps one id', () async {
      final s = InMemoryInstallationIdStore();
      expect(await s.get(), await s.get());
    });
  });
}
