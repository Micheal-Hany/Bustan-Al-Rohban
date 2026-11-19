import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/chat_api.dart';
import '../domain/client_identity.dart';
import '../domain/report.dart';
import '../../bookmarks/domain/bookmark_store.dart' show randomId;

/// Sends an answer report to `POST /v1/reports`. Sends exactly
/// [ReportPayload.toJson] plus the rate-limit/attestation fields (which the
/// server does not store).
class HttpReportSender implements ReportSender {
  HttpReportSender({
    required this.baseUrl,
    required this.installationIds,
    this.attestation = const NoAttestationProvider(),
    this.timeout = const Duration(seconds: 20),
  });

  final String baseUrl;
  final InstallationIdStore installationIds;
  final AttestationProvider attestation;
  final Duration timeout;

  @override
  Future<void> send(ReportPayload payload) async {
    if (baseUrl.isEmpty) throw const ReportUnavailable();
    try {
      await _post(payload).timeout(timeout);
    } on ChatApiException {
      rethrow;
    } on ReportUnavailable {
      rethrow;
    } on TimeoutException {
      throw const ChatApiException(ChatErrorKind.timeout);
    } on SocketException {
      throw const ChatApiException(ChatErrorKind.offline);
    } on HandshakeException {
      throw const ChatApiException(ChatErrorKind.offline);
    } on HttpException {
      throw const ChatApiException(ChatErrorKind.offline);
    }
  }

  Future<void> _post(ReportPayload payload) async {
    final requestId = randomId('req');
    final body = {
      ...payload.toJson(),
      'requestId': requestId,
      'installationId': await installationIds.get(),
      if (await attestation.tokenFor(requestId) case final token?)
        'attestationToken': token,
    };
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final base = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      final req = await client.postUrl(Uri.parse('$base/v1/reports'));
      req.headers.contentType =
          ContentType('application', 'json', charset: 'utf-8');
      req.add(utf8.encode(jsonEncode(body)));
      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode == 202) return;
      throw _error(res.statusCode, text);
    } finally {
      client.close(force: true);
    }
  }

  Object _error(int status, String text) {
    String? code;
    int? retry;
    try {
      final j = jsonDecode(text);
      final e = j is Map ? j['error'] : null;
      if (e is Map) {
        code = e['code'] is String ? e['code'] as String : null;
        retry = e['retryAfterSeconds'] is int ? e['retryAfterSeconds'] as int : null;
      }
    } catch (_) {}
    if (status == 503 && code == 'reports_unavailable') {
      return const ReportUnavailable();
    }
    if (status == 429) {
      return ChatApiException(ChatErrorKind.rateLimited, retryAfterSeconds: retry);
    }
    if (status == 403) return const ChatApiException(ChatErrorKind.attestation);
    if (status == 503) return const ChatApiException(ChatErrorKind.unavailable);
    if (status == 400 || status == 413) {
      return const ChatApiException(ChatErrorKind.badResponse);
    }
    return const ChatApiException(ChatErrorKind.server);
  }
}
