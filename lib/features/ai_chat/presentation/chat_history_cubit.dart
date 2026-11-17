import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/strings.dart';
import '../../library/presentation/load_status.dart';
import '../domain/chat_models.dart';
import '../domain/chat_store.dart';

class ChatHistoryState {
  const ChatHistoryState({
    required this.status,
    this.conversations = const [],
    this.error,
  });

  final LoadStatus status;
  final List<Conversation> conversations;
  final String? error;
}

/// The conversation list: reopen, delete one, clear all.
class ChatHistoryCubit extends Cubit<ChatHistoryState> {
  ChatHistoryCubit(this._store)
      : super(const ChatHistoryState(status: LoadStatus.loading));

  final ChatStore _store;

  Future<void> load() async {
    try {
      final list = await _store.conversations();
      if (isClosed) return;
      emit(ChatHistoryState(
        status: list.isEmpty ? LoadStatus.empty : LoadStatus.loaded,
        conversations: list,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(const ChatHistoryState(
        status: LoadStatus.error,
        error: AppStrings.chatLoadFailed,
      ));
    }
  }

  Future<void> delete(String id) async {
    try {
      await _store.deleteConversation(id);
    } catch (_) {
      if (isClosed) return;
      emit(ChatHistoryState(
        status: LoadStatus.loaded,
        conversations: state.conversations,
        error: AppStrings.chatLoadFailed,
      ));
      return;
    }
    await load();
  }

  Future<void> clearAll() async {
    try {
      await _store.clearAll();
    } catch (_) {
      if (isClosed) return;
      emit(ChatHistoryState(
        status: LoadStatus.loaded,
        conversations: state.conversations,
        error: AppStrings.chatLoadFailed,
      ));
      return;
    }
    await load();
  }

  /// Creates an empty book-scope conversation and returns its id.
  Future<String> create() async {
    final c = await _store.createConversation();
    await load();
    return c.id;
  }
}
