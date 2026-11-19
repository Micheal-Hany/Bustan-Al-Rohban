import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/assistant_reply.dart';
import '../domain/chat_api.dart';

/// Talks to the backend's `POST /v1/chat` over plain dart:io (no extra
/// package). Release builds must use an https base URL (the Android cleartext
/// exception exists in the debug manifest only).
class HttpChatApi implements ChatApi {
  HttpChatApi({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 45),
    this.connectTimeout = const Duration(seconds: 10),
  });

  final String baseUrl;

  /// Whole-request limit (the backend itself gives the model 30 s).
  final Duration timeout;
  final Duration connectTimeout;

  @override
  Future<AssistantReply> ask(ChatRequest request) async {
    try {
      return await _send(request).timeout(timeout);
    } on ChatApiException {
      rethrow;
    } on TimeoutException {
      throw const ChatApiException(ChatErrorKind.timeout);
    } on SocketException {
      throw const ChatApiException(ChatErrorKind.offline);
    } on HandshakeException {
      throw const ChatApiException(ChatErrorKind.offline);
    } on HttpException {
      throw const ChatApiException(ChatErrorKind.offline);
    } on FormatException {
      throw const ChatApiException(ChatErrorKind.badResponse);
    }
  }

  Future<AssistantReply> _send(ChatRequest request) async {
    final client = HttpClient()..connectionTimeout = connectTimeout;
    try {
      final base = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      final req = await client.postUrl(Uri.parse('$base/v1/chat'));
      req.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
      req.add(utf8.encode(jsonEncode(request.toJson())));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode == 200) {
        final j = jsonDecode(body);
        if (j is! Map) throw const FormatException('not an object');
        return AssistantReply.fromJson(Map<String, dynamic>.from(j));
      }
      throw _errorFor(res.statusCode, body);
    } finally {
      client.close(force: true);
    }
  }
}

/// Maps an HTTP failure to an error kind. Never keeps the response body.
ChatApiException _errorFor(int status, String body) {
  int? retry;
  try {
    final j = jsonDecode(body);
    final e = j is Map ? j['error'] : null;
    if (e is Map && e['retryAfterSeconds'] is int) {
      retry = e['retryAfterSeconds'] as int;
    }
  } catch (_) {}
  if (status == 429) {
    return ChatApiException(ChatErrorKind.rateLimited, retryAfterSeconds: retry);
  }
  if (status == 403) return const ChatApiException(ChatErrorKind.attestation);
  if (status == 504 || status == 408) {
    return const ChatApiException(ChatErrorKind.timeout);
  }
  if (status == 503) return const ChatApiException(ChatErrorKind.unavailable);
  if (status == 400 || status == 413) {
    return const ChatApiException(ChatErrorKind.badResponse);
  }
  return const ChatApiException(ChatErrorKind.server);
}
