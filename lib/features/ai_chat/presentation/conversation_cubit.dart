import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/strings.dart';
import '../../library/presentation/load_status.dart';
import '../domain/chat_models.dart';
import '../domain/chat_store.dart';

class ConversationState {
  const ConversationState({
    required this.status,
    this.conversation,
    this.messages = const [],
    this.error,
  });

  final LoadStatus status;
  final Conversation? conversation;
  final List<ChatMessage> messages;
  final String? error;
}

/// One stored conversation. Reading works offline; the real assistant reply
/// arrives in Task 11 (this task only stores and shows messages).
class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit(this._store, this.conversationId)
      : super(const ConversationState(status: LoadStatus.loading));

  final ChatStore _store;
  final String conversationId;

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
      if (isClosed) return;
      emit(ConversationState(
        status: messages.isEmpty ? LoadStatus.empty : LoadStatus.loaded,
        conversation: c,
        messages: messages,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(const ConversationState(
          status: LoadStatus.error, error: AppStrings.chatLoadFailed));
    }
  }

  /// Development helper (Task 9 manual check): stores a user message and a
  /// FAKE assistant reply. Replaced by the real flow in Task 11.
  Future<void> addTestExchange(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      await _store.addMessage(
        conversationId: conversationId,
        role: ChatRole.user,
        content: trimmed,
      );
      await _store.addMessage(
        conversationId: conversationId,
        role: ChatRole.assistant,
        content: AppStrings.chatTestReply,
      );
    } catch (_) {
      if (isClosed) return;
      emit(ConversationState(
        status: state.status,
        conversation: state.conversation,
        messages: state.messages,
        error: AppStrings.chatLoadFailed,
      ));
      return;
    }
    await load();
  }
}
