import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/strings.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/widgets/status_views.dart';
import '../../library/presentation/load_status.dart';
import '../domain/chat_models.dart';
import '../domain/chat_store.dart';
import 'chat_history_cubit.dart';

String scopeLabel(ChatScopeKind scope) => switch (scope) {
      ChatScopeKind.book => AppStrings.chatScopeBook,
      ChatScopeKind.saint => AppStrings.chatScopeSaint,
      ChatScopeKind.section => AppStrings.chatScopeSection,
    };

/// Past conversations, most recently updated first. Works offline.
class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key, this.showDevTools = kDebugMode});

  /// Shows the debug-only "new conversation" button.
  final bool showDevTools;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ChatHistoryCubit(context.read<ChatStore>())..load(),
      child: _View(showDevTools: showDevTools),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.showDevTools});

  final bool showDevTools;

  Future<void> _confirmClear(BuildContext context) async {
    final cubit = context.read<ChatHistoryCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('chat-clear-dialog'),
        title: const Text(AppStrings.chatClearConfirmTitle),
        content: const Text(AppStrings.chatClearConfirmBody),
        actions: [
          TextButton(
            key: const Key('chat-clear-cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.chatCancel),
          ),
          TextButton(
            key: const Key('chat-clear-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.chatConfirm),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatHistoryCubit, ChatHistoryState>(
      builder: (context, state) {
        return Scaffold(
          key: const Key('chat-screen'),
          appBar: AppBar(
            title: const Text(AppStrings.chat),
            actions: [
              if (state.conversations.isNotEmpty)
                IconButton(
                  key: const Key('chat-clear-all'),
                  tooltip: AppStrings.chatClearAll,
                  icon: const Icon(AppIcons.delete),
                  onPressed: () => _confirmClear(context),
                ),
            ],
          ),
          floatingActionButton: showDevTools
              ? FloatingActionButton(
                  key: const Key('chat-new-debug'),
                  tooltip: AppStrings.chatNewConversation,
                  onPressed: () async {
                    final id = await context.read<ChatHistoryCubit>().create();
                    if (context.mounted) {
                      await context.push(AppRoutes.conversation(id));
                      if (context.mounted) {
                        context.read<ChatHistoryCubit>().load();
                      }
                    }
                  },
                  child: const Icon(AppIcons.add),
                )
              : null,
          body: Column(children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                AppStrings.chatPrivacyNote,
                key: Key('chat-privacy-note'),
              ),
            ),
            Expanded(child: _body(context, state)),
          ]),
        );
      },
    );
  }

  Widget _body(BuildContext context, ChatHistoryState state) {
    switch (state.status) {
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          details: state.error ?? AppStrings.chatLoadFailed,
          onRetry: () => context.read<ChatHistoryCubit>().load(),
        );
      case LoadStatus.empty:
        return const EmptyView(message: AppStrings.chatEmpty);
      case LoadStatus.loaded:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final c in state.conversations)
              Card(
                child: ListTile(
                  key: Key('conversation-${c.id}'),
                  leading: const Icon(AppIcons.chat),
                  title: Text(
                    c.title.isEmpty ? AppStrings.chatNewConversation : c.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(scopeLabel(c.scope)),
                  trailing: IconButton(
                    key: Key('conversation-delete-${c.id}'),
                    tooltip: AppStrings.chatDelete,
                    icon: const Icon(AppIcons.delete),
                    onPressed: () =>
                        context.read<ChatHistoryCubit>().delete(c.id),
                  ),
                  onTap: () async {
                    final cubit = context.read<ChatHistoryCubit>();
                    await context.push(AppRoutes.conversation(c.id));
                    cubit.load(); // order may have changed
                  },
                ),
              ),
          ],
        );
    }
  }
}
