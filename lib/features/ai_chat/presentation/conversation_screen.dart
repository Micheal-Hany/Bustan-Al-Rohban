import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/strings.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/status_views.dart';
import '../../library/presentation/load_status.dart';
import '../domain/chat_models.dart';
import '../domain/chat_store.dart';
import 'conversation_cubit.dart';

/// One stored conversation (read-only, works offline). The debug-only test
/// composer exists so history can be checked before the real chat (Task 11).
class ConversationScreen extends StatelessWidget {
  const ConversationScreen({
    super.key,
    required this.conversationId,
    this.showTestComposer = kDebugMode,
  });

  final String conversationId;
  final bool showTestComposer;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ConversationCubit(context.read<ChatStore>(), conversationId)..load(),
      child: _View(showTestComposer: showTestComposer),
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this.showTestComposer});

  final bool showTestComposer;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationCubit, ConversationState>(
      builder: (context, state) {
        final title = state.conversation == null ||
                state.conversation!.title.isEmpty
            ? AppStrings.chatNewConversation
            : state.conversation!.title;
        return Scaffold(
          key: const Key('conversation-screen'),
          appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
          body: Column(children: [
            Expanded(child: _body(context, state)),
            if (widget.showTestComposer) _composer(context),
          ]),
        );
      },
    );
  }

  Widget _body(BuildContext context, ConversationState state) {
    switch (state.status) {
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          details: state.error ?? AppStrings.chatLoadFailed,
          onRetry: () => context.read<ConversationCubit>().load(),
        );
      case LoadStatus.empty:
        return const EmptyView(message: AppStrings.chatEmptyConversation);
      case LoadStatus.loaded:
        return ListView(
          key: const Key('conversation-messages'),
          padding: const EdgeInsets.all(16),
          children: [
            for (final m in state.messages) _Bubble(message: m),
          ],
        );
    }
  }

  Widget _composer(BuildContext context) {
    final cubit = context.read<ConversationCubit>();
    Future<void> send() async {
      final text = _controller.text;
      _controller.clear();
      await cubit.addTestExchange(text);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          Expanded(
            child: TextField(
              key: const Key('chat-test-input'),
              controller: _controller,
              decoration:
                  const InputDecoration(hintText: AppStrings.chatTestHint),
              onSubmitted: (_) => send(),
            ),
          ),
          IconButton(
            key: const Key('chat-test-send'),
            tooltip: AppStrings.chatSend,
            icon: const Icon(AppIcons.send),
            onPressed: send,
          ),
        ]),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = message.role == ChatRole.user;
    final note = switch (message.status) {
      MessageStatus.failed => AppStrings.chatMessageFailed,
      MessageStatus.pending => AppStrings.chatMessagePending,
      MessageStatus.sent => null,
    };
    return Align(
      // In RTL, "start" is the right side: the user's messages.
      alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: Container(
        key: Key('message-${message.id}'),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: mine ? scheme.primary : Colors.white,
          border: Border.all(color: AppTheme.goldSoft),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(color: mine ? scheme.onPrimary : null),
            ),
            if (note != null)
              Text(note,
                  key: Key('message-status-${message.id}'),
                  style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
