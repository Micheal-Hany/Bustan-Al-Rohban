import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/strings.dart';
import '../../bookmarks/domain/bookmark_store.dart' show randomId;
import '../../library/presentation/load_status.dart';
import '../domain/assistant_reply.dart';
import '../domain/chat_api.dart';
import '../domain/chat_models.dart';
import '../domain/chat_store.dart';
import '../domain/client_identity.dart';
import '../domain/context_window.dart';

enum SendStatus { idle, sending, failed }

class ConversationState {
  const ConversationState({
    required this.status,
    this.conversation,
    this.messages = const [],
    this.error,
    this.scopeTitle,
    this.sendStatus = SendStatus.idle,
    this.pendingText,
    this.errorKind,
    this.retryAfterSeconds,
  });

  final LoadStatus status;
  final Conversation? conversation;
  final List<ChatMessage> messages;
  final String? error;

  /// Saint title for a saint/section scope (null for the whole book).
  final String? scopeTitle;
  final SendStatus sendStatus;

  /// The question being answered right now (shown, not yet saved).
  final String? pendingText;
  final ChatErrorKind? errorKind;
  final int? retryAfterSeconds;

  ConversationState copyWith({
    LoadStatus? status,
    SendStatus? sendStatus,
    String? pendingText,
    ChatErrorKind? errorKind,
    int? retryAfterSeconds,
    bool clearSend = false,
  }) =>
      ConversationState(
        status: status ?? this.status,
        conversation: conversation,
        messages: messages,
        error: error,
        scopeTitle: scopeTitle,
        sendStatus: clearSend ? SendStatus.idle : sendStatus ?? this.sendStatus,
        pendingText: clearSend ? null : pendingText ?? this.pendingText,
        errorKind: clearSend ? null : errorKind ?? this.errorKind,
        retryAfterSeconds:
            clearSend ? null : retryAfterSeconds ?? this.retryAfterSeconds,
      );
}

/// One conversation: reading works offline; sending needs the network.
/// The question is saved together with its reply only after the reply
/// arrived, so a failed send leaves no half conversation and the text the
/// user typed stays in the input box for another try.
class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit(
    this._store,
    this.conversationId, {
    ChatApi api = const UnconfiguredChatApi(),
    InstallationIdStore? installationIds,
    AttestationProvider attestation = const NoAttestationProvider(),
    Future<String?> Function(String saintId)? saintTitle,
    Future<int?> Function()? contentVersion,
    String Function()? newRequestId,
    this.limits = const ContextLimits(),
  })  : _api = api,
        _ids = installationIds ?? InMemoryInstallationIdStore(),
        _attestation = attestation,
        _saintTitle = saintTitle,
        _contentVersion = contentVersion,
        _newRequestId = newRequestId ?? (() => randomId('req')),
        super(const ConversationState(status: LoadStatus.loading));

  final ChatStore _store;
  final String conversationId;
  final ChatApi _api;
  final InstallationIdStore _ids;
  final AttestationProvider _attestation;
  final Future<String?> Function(String saintId)? _saintTitle;
  final Future<int?> Function()? _contentVersion;
  final String Function() _newRequestId;
  final ContextLimits limits;

  Future<void> load() async {
    try {
      final c = await _store.conversation(conversationId);
      if (isClosed) return;
      if (c == null) {
        emit(const ConversationState(
            status: LoadStatus.error, error: AppStrings.notFound));
        return;
      }
      final messages = await _store.messages(conversationId);
      String? scopeTitle;
      if (c.saintId != null && _saintTitle != null) {
        try {
          scopeTitle = await _saintTitle(c.saintId!);
        } catch (_) {
          scopeTitle = null; // the scope label falls back to a generic one
        }
      }
      if (isClosed) return;
      emit(ConversationState(
        status: messages.isEmpty ? LoadStatus.empty : LoadStatus.loaded,
        conversation: c,
        messages: messages,
        scopeTitle: scopeTitle,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(const ConversationState(
          status: LoadStatus.error, error: AppStrings.chatLoadFailed));
    }
  }

  /// Sends [text]. Returns true when the answer was received and saved
  /// (the caller then clears the input); false keeps the text for a retry.
  Future<bool> send(String text) async {
    final question = text.trim();
    final conversation = state.conversation;
    if (question.isEmpty ||
        conversation == null ||
        state.sendStatus == SendStatus.sending) {
      return false;
    }
    emit(state.copyWith(
        sendStatus: SendStatus.sending, pendingText: question));
    final AssistantReply reply;
    try {
      final history = await _store.messages(conversationId);
      final requestId = _newRequestId();
      reply = await _api.ask(ChatRequest(
        requestId: requestId,
        installationId: await _ids.get(),
        bookScope: conversation.scope == ChatScopeKind.book,
        saintId: conversation.saintId,
        sectionId: conversation.sectionId,
        messages: buildContext(history, question, limits: limits),
        attestationToken: await _attestation.tokenFor(requestId),
      ));
    } on ChatApiException catch (e) {
      return _failed(e.kind, e.retryAfterSeconds);
    } catch (_) {
      return _failed(ChatErrorKind.server, null);
    }
    try {
      int? version;
      try {
        version = await _contentVersion?.call();
      } catch (_) {
        version = null;
      }
      await _store.addMessage(
        conversationId: conversationId,
        role: ChatRole.user,
        content: question,
      );
      await _store.addMessage(
        conversationId: conversationId,
        role: ChatRole.assistant,
        content: reply.plainText,
        metaJson: encodeStoredReply(reply, version),
      );
    } catch (_) {
      return _failed(ChatErrorKind.storage, null);
    }
    await load();
    return true;
  }

  bool _failed(ChatErrorKind kind, int? retryAfter) {
    if (!isClosed) {
      emit(state.copyWith(
        sendStatus: SendStatus.failed,
        errorKind: kind,
        retryAfterSeconds: retryAfter,
      ).withoutPending());
    }
    return false;
  }

  /// Hides the "send failed" banner.
  void dismissError() {
    if (state.sendStatus == SendStatus.failed) {
      emit(state.copyWith(clearSend: true));
    }
  }
}

extension on ConversationState {
  ConversationState withoutPending() => ConversationState(
        status: status,
        conversation: conversation,
        messages: messages,
        error: error,
        scopeTitle: scopeTitle,
        sendStatus: sendStatus,
        pendingText: null,
        errorKind: errorKind,
        retryAfterSeconds: retryAfterSeconds,
      );
}
