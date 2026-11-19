import 'assistant_reply.dart';

/// Why a question could not be answered. Each maps to a distinct message.
enum ChatErrorKind {
  /// No backend address is configured in this build.
  notConfigured,

  /// The device could not reach the server (no internet).
  offline,
  timeout,

  /// Too many requests (429).
  rateLimited,

  /// Spend cap, kill switch, busy provider (503).
  unavailable,

  /// The app could not be verified (403 attestation).
  attestation,
  server,
  badResponse,

  /// The reply arrived but could not be saved on the device.
  storage,
}

class ChatApiException implements Exception {
  const ChatApiException(this.kind, {this.retryAfterSeconds});

  final ChatErrorKind kind;
  final int? retryAfterSeconds;

  @override
  String toString() => 'ChatApiException(${kind.name})';
}

class RequestMessage {
  const RequestMessage(this.role, this.text);

  /// `user` or `assistant`.
  final String role;
  final String text;

  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

/// One stateless chat request (SPEC 12.3). The scope travels in its own
/// fields: it is never inferred from the messages.
class ChatRequest {
  const ChatRequest({
    required this.requestId,
    required this.installationId,
    required this.bookScope,
    this.saintId,
    this.sectionId,
    required this.messages,
    this.attestationToken,
  });

  final String requestId;
  final String installationId;

  /// True for `book_scope`; false for `saint_scope` (with [saintId]).
  final bool bookScope;
  final String? saintId;
  final String? sectionId;
  final List<RequestMessage> messages;
  final String? attestationToken;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'installationId': installationId,
        'mode': bookScope ? 'book_scope' : 'saint_scope',
        'scope': {
          if (!bookScope) 'saintId': saintId,
          if (!bookScope && sectionId != null) 'sectionId': sectionId,
        },
        'messages': [for (final m in messages) m.toJson()],
        if (attestationToken != null) 'attestationToken': attestationToken,
      };
}

abstract class ChatApi {
  /// Throws [ChatApiException].
  Future<AssistantReply> ask(ChatRequest request);
}

/// Used when no backend address is configured: every ask fails cleanly.
class UnconfiguredChatApi implements ChatApi {
  const UnconfiguredChatApi();

  @override
  Future<AssistantReply> ask(ChatRequest request) async =>
      throw const ChatApiException(ChatErrorKind.notConfigured);
}
