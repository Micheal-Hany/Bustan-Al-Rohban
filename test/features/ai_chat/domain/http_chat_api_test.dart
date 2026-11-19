import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bustan_al_rohban/features/ai_chat/data/file_installation_id_store.dart';
import 'package:bustan_al_rohban/features/ai_chat/data/http_chat_api.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/assistant_reply.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_api.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/client_identity.dart';
import 'package:flutter_test/flutter_test.dart';

// Plain `test` (not testWidgets): real loopback sockets are allowed here.

const _request = ChatRequest(
  requestId: 'req-1',
  installationId: 'inst-0123456789abcdef',
  bookScope: false,
  saintId: 'saint-a',
  messages: [RequestMessage('user', 'ما هي المحبة؟')],
  attestationToken: 'tok',
);

typedef _Handler = Future<void> Function(HttpRequest req, String body);

Future<(HttpServer, HttpChatApi)> _start(
  _Handler handler, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    final body = await utf8.decoder.bind(req).join();
    await handler(req, body);
  });
  return (
    server,
    HttpChatApi(baseUrl: 'http://127.0.0.1:${server.port}', timeout: timeout),
  );
}

Future<void> _json(HttpRequest r, int status, Object body) async {
  r.response.statusCode = status;
  r.response.headers.contentType = ContentType.json;
  r.response.write(jsonEncode(body));
  await r.response.close();
}

Future<Object?> _err(Future<Object?> f) async {
  try {
    await f;
    return null;
  } catch (e) {
    return e;
  }
}

void main() {
  test('posts the request and parses an answered reply', () async {
    String? seenBody;
    String? seenPath;
    final (server, api) = await _start((r, body) async {
      seenBody = body;
      seenPath = r.uri.path;
      await _json(r, 200, {
        'requestId': 'req-1',
        'status': 'answered',
        'blocks': [
          {
            'type': 'paraphrase',
            'text': 'ملخص',
            'citations': ['p-000001'],
            'references': [
              {
                'paragraphId': 'p-000001',
                'saintId': 'saint-a',
                'saintTitle': 'ا',
                'sectionId': 'sec-a-001',
                'sectionTitle': 'ب',
                'page': 3,
              }
            ],
          }
        ],
        'meta': {'provider': 'fake', 'model': 'm'},
      });
    });
    addTearDown(() => server.close(force: true));
    final reply = await api.ask(_request) as AnsweredReply;
    expect(reply.blocks.single.references.single.page, 3);
    expect(seenPath, '/v1/chat');
    final sent = jsonDecode(seenBody!) as Map<String, dynamic>;
    expect(sent['mode'], 'saint_scope');
    expect((sent['scope'] as Map)['saintId'], 'saint-a');
    expect(sent['attestationToken'], 'tok');
    expect((sent['messages'] as List).single['text'], 'ما هي المحبة؟');
  });

  test('parses refused and safety replies', () async {
    final (s1, a1) = await _start((r, _) => _json(r, 200, {
          'status': 'refused',
          'reason': 'insufficient_evidence',
          'message': 'لم أجد',
        }));
    addTearDown(() => s1.close(force: true));
    expect(await a1.ask(_request), isA<RefusedReply>());

    final (s2, a2) = await _start((r, _) => _json(r, 200, {
          'status': 'safety',
          'category': 'self_harm',
          'message': 'م',
          'referral': ['emergency'],
        }));
    addTearDown(() => s2.close(force: true));
    expect(await a2.ask(_request), isA<SafetyReply>());
  });

  for (final c in <(int, ChatErrorKind)>[
    (429, ChatErrorKind.rateLimited),
    (403, ChatErrorKind.attestation),
    (503, ChatErrorKind.unavailable),
    (504, ChatErrorKind.timeout),
    (502, ChatErrorKind.server),
    (500, ChatErrorKind.server),
    (413, ChatErrorKind.badResponse),
  ]) {
    test('HTTP ${c.$1} maps to ${c.$2.name}', () async {
      final (server, api) = await _start((r, _) => _json(r, c.$1, {
            'error': {'code': 'x', 'message': 'm', 'retryAfterSeconds': 42},
          }));
      addTearDown(() => server.close(force: true));
      final e = await _err(api.ask(_request));
      expect(e, isA<ChatApiException>());
      expect((e as ChatApiException).kind, c.$2);
      if (c.$1 == 429) expect(e.retryAfterSeconds, 42);
    });
  }

  test('an unparseable 200 body is badResponse', () async {
    final (server, api) = await _start((r, _) async {
      r.response.write('not json');
      await r.response.close();
    });
    addTearDown(() => server.close(force: true));
    final e = await _err(api.ask(_request));
    expect((e as ChatApiException).kind, ChatErrorKind.badResponse);
  });

  test('a server that never answers is a timeout', () async {
    final (server, api) = await _start(
      (r, _) => Completer<void>().future, // never responds
      timeout: const Duration(milliseconds: 200),
    );
    addTearDown(() => server.close(force: true));
    final e = await _err(api.ask(_request));
    expect((e as ChatApiException).kind, ChatErrorKind.timeout);
  });

  test('an unreachable server is offline', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close(force: true); // nothing listens on this port now
    final api = HttpChatApi(baseUrl: 'http://127.0.0.1:$port');
    final e = await _err(api.ask(_request));
    expect((e as ChatApiException).kind, ChatErrorKind.offline);
  });

  group('FileInstallationIdStore', () {
    test('creates, persists and re-reads the same id', () async {
      final dir = await Directory.systemTemp.createTemp('inst');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/sub/installation_id');
      final a = await FileInstallationIdStore(file).get();
      expect(installationIdPattern.hasMatch(a), isTrue);
      expect(await FileInstallationIdStore(file).get(), a);
    });

    test('replaces a corrupt file with a valid id', () async {
      final dir = await Directory.systemTemp.createTemp('inst');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/installation_id')..writeAsStringSync('x y');
      final id = await FileInstallationIdStore(file).get();
      expect(installationIdPattern.hasMatch(id), isTrue);
    });
  });
}
