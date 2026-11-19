import '../../../app/strings.dart';
import '../domain/chat_api.dart';

/// User-facing text for a failed request (chat and report).
String errorText(ChatErrorKind kind, int? retryAfter) => switch (kind) {
      ChatErrorKind.notConfigured => AppStrings.chatErrNotConfigured,
      ChatErrorKind.offline => AppStrings.chatErrOffline,
      ChatErrorKind.timeout => AppStrings.chatErrTimeout,
      ChatErrorKind.rateLimited => retryAfter == null
          ? AppStrings.chatErrRateLimited
          : '${AppStrings.chatErrRateLimited} ($retryAfter ${AppStrings.chatSecondsWord})',
      ChatErrorKind.unavailable => AppStrings.chatErrUnavailable,
      ChatErrorKind.attestation => AppStrings.chatErrAttestation,
      ChatErrorKind.server => AppStrings.chatErrServer,
      ChatErrorKind.badResponse => AppStrings.chatErrBadResponse,
      ChatErrorKind.storage => AppStrings.chatErrStorage,
    };
