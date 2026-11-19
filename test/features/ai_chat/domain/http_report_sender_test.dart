import 'dart:convert';
import 'dart:io';

import 'package:bustan_al_rohban/features/ai_chat/data/file_chat_notice_store.dart';
import 'package:bustan_al_rohban/features/ai_chat/data/http_report_sender.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_api.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/client_identity.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/report.dart';
import 'package:flutter_test/flutter_test.dart';

const _payload = ReportPayload(
  reason: ReportReason.notFromBook,
  note: 'ملاحظة',
  answerText: 'نص الإجابة',
  question: 'السؤال',
  citedParagraphIds: ['p-000001'],
  contentVersion: 7,
  provider: 'openai',
  model: 'm1',
);

Future<Object?> _err(Future<void> f) async {
  try {
    await f;
    return null;
  } catch (e) {
    return e;
  }
}

Future<(HttpServer, HttpReportSender, List<Map<String, dynamic>>)> _start(
  int status,
  Object body, {
  AttestationProvider attestation = const NoAttestationProvider(),
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final seen = <Map<String, dynamic>>[];
  server.listen((req) async {
    final text = await utf8.decoder.bind(req).join();
    seen.add({
      'path': req.uri.path,
      'json': jsonDecode(text),
    });
    req.response.statusCode = status;
    req.response.headers.contentType = ContentType.json;
    req.response.write(jsonEncode(body));
    await req.response.close();
  });
  return (
    server,
    HttpReportSender(
      baseUrl: 'http://127.0.0.1:${server.port}',
      installationIds: InMemoryInstallationIdStore(),
      attestation: attestation,
    ),
    seen,
  );
}

void main() {
  test('posts exactly the report fields plus the rate-limit fields', () async {
    final (server, sender, seen) = await _start(
      202,
      {'reportId': 'r1', 'stored': true},
      attestation: const FixedAttestationProvider('tok'),
    );
    addTearDown(() => server.close(force: true));
    await sender.send(_payload);
    expect(seen.single['path'], '/v1/reports');
    final json = seen.single['json'] as Map<String, dynamic>;
    expect(json.keys.toSet(), {
      'reason', 'note', 'answerText', 'question', 'citedParagraphIds',
      'contentVersion', 'provider', 'model',
      'requestId', 'installationId', 'attestationToken',
    });
    expect(json['reason'], 'not_from_book');
    expect(json['citedParagraphIds'], ['p-000001']);
    expect(installationIdPattern.hasMatch(json['installationId'] as String), isTrue);
    expect(json.containsKey('messages'), isFalse); // no conversation history
  });

  test('omits the attestation token when there is none', () async {
    final (server, sender, seen) = await _start(202, {'stored': true});
    addTearDown(() => server.close(force: true));
    await sender.send(_payload);
    expect((seen.single['json'] as Map).containsKey('attestationToken'), isFalse);
  });

  test('reports_unavailable maps to ReportUnavailable', () async {
    final (server, sender, _) = await _start(
        503, {'error': {'code': 'reports_unavailable', 'message': 'm'}});
    addTearDown(() => server.close(force: true));
    expect(await _err(sender.send(_payload)), isA<ReportUnavailable>());
  });

  for (final c in <(int, ChatErrorKind)>[
    (429, ChatErrorKind.rateLimited),
    (403, ChatErrorKind.attestation),
    (503, ChatErrorKind.unavailable),
    (400, ChatErrorKind.badResponse),
    (500, ChatErrorKind.server),
  ]) {
    test('HTTP ${c.$1} maps to ${c.$2.name}', () async {
      final (server, sender, _) = await _start(
          c.$1, {'error': {'code': 'x', 'message': 'm', 'retryAfterSeconds': 9}});
      addTearDown(() => server.close(force: true));
      final e = await _err(sender.send(_payload));
      expect((e as ChatApiException).kind, c.$2);
    });
  }

  test('an unreachable server is offline', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close(force: true);
    final sender = HttpReportSender(
      baseUrl: 'http://127.0.0.1:$port',
      installationIds: InMemoryInstallationIdStore(),
    );
    expect(((await _err(sender.send(_payload))) as ChatApiException).kind,
        ChatErrorKind.offline);
  });

  test('without a configured address nothing is sent', () async {
    final sender = HttpReportSender(
        baseUrl: '', installationIds: InMemoryInstallationIdStore());
    expect(await _err(sender.send(_payload)), isA<ReportUnavailable>());
  });

  group('FileChatNoticeStore', () {
    test('is false until accepted, then stays true', () async {
      final dir = await Directory.systemTemp.createTemp('notice');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/sub/chat_notice_seen');
      expect(await FileChatNoticeStore(file).accepted(), isFalse);
      await FileChatNoticeStore(file).accept();
      expect(await FileChatNoticeStore(file).accepted(), isTrue);
    });
  });
}
