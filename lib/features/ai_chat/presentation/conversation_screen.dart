import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/strings.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/status_views.dart';
import '../../library/data/library_repository.dart';
import '../../library/presentation/load_status.dart';
import '../domain/assistant_reply.dart';
import '../domain/chat_api.dart';
import '../domain/chat_models.dart';
import '../domain/chat_notice_store.dart';
import '../domain/chat_store.dart';
import '../domain/client_identity.dart';
import 'chat_error_text.dart';
import 'chat_notice_dialog.dart';
import 'conversation_cubit.dart';
import 'report_screen.dart';
import 'scope_sheet.dart';

/// One conversation: reading works offline, sending needs the network.
class ConversationScreen extends StatelessWidget {
  const ConversationScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final library = context.read<LibraryRepository>();
    return BlocProvider(
      create: (context) => ConversationCubit(
        context.read<ChatStore>(),
        conversationId,
        api: context.read<ChatApi>(),
        installationIds: context.read<InstallationIdStore>(),
        attestation: context.read<AttestationProvider>(),
        saintTitle: (id) async => (await library.entry(id))?.title,
        contentVersion: () async => (await library.manifest()).contentVersion,
      )..load(),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

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

  Future<void> _send() async {
    final cubit = context.read<ConversationCubit>();
    final notice = context.read<ChatNoticeStore>();
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    // The "what is sent" notice comes once, before the first question leaves
    // the device. Declining sends nothing and keeps the typed text.
    if (!await notice.accepted()) {
      if (!mounted) return;
      if (!await showChatNoticeDialog(context)) return;
      await notice.accept();
    }
    final ok = await cubit.send(text);
    // Clear only after success; on failure the typed text stays.
    if (ok && mounted && _controller.text == text) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationCubit, ConversationState>(
      builder: (context, state) {
        final title =
            state.conversation == null || state.conversation!.title.isEmpty
                ? AppStrings.chatNewConversation
                : state.conversation!.title;
        return Scaffold(
          key: const Key('conversation-screen'),
          appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
          body: Column(children: [
            _ScopeBar(state: state),
            Expanded(child: _body(context, state)),
            if (state.sendStatus == SendStatus.failed)
              _ErrorBanner(state: state, onRetry: _send),
            if (state.conversation != null) _composer(context, state),
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
        if (state.sendStatus == SendStatus.sending) {
          return _list(context, state);
        }
        return const Center(
          key: Key('empty-view'),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(AppStrings.chatAskPrompt, textAlign: TextAlign.center),
          ),
        );
      case LoadStatus.loaded:
        return _list(context, state);
    }
  }

  Widget _list(BuildContext context, ConversationState state) {
    final sending = state.sendStatus == SendStatus.sending;
    return ListView(
      key: const Key('conversation-messages'),
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < state.messages.length; i++)
          state.messages[i].role == ChatRole.user
              ? _UserBubble(text: state.messages[i].content, id: state.messages[i].id)
              : _AssistantBubble(
                  message: state.messages[i],
                  question: _questionBefore(state.messages, i),
                ),
        if (sending && state.pendingText != null)
          _UserBubble(text: state.pendingText!, id: 'pending'),
        if (sending)
          const Padding(
            key: Key('sending-indicator'),
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(AppStrings.chatSending),
            ]),
          ),
      ],
    );
  }

  String _questionBefore(List<ChatMessage> all, int i) {
    for (var j = i - 1; j >= 0; j--) {
      if (all[j].role == ChatRole.user) return all[j].content;
    }
    return '';
  }

  Widget _composer(BuildContext context, ConversationState state) {
    final sending = state.sendStatus == SendStatus.sending;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: TextField(
              key: const Key('chat-input'),
              controller: _controller,
              enabled: !sending,
              minLines: 1,
              maxLines: 4,
              maxLength: 1000,
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(
                hintText: AppStrings.chatInputHint,
                counterText: '',
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          IconButton(
            key: const Key('chat-send'),
            tooltip: AppStrings.chatSend,
            icon: const Icon(AppIcons.send),
            onPressed: sending ? null : _send,
          ),
        ]),
      ),
    );
  }
}

class _ScopeBar extends StatelessWidget {
  const _ScopeBar({required this.state});

  final ConversationState state;

  String _scopeText() {
    final c = state.conversation;
    if (c == null || c.scope == ChatScopeKind.book) {
      return AppStrings.chatScopeBookFull;
    }
    final saint = state.scopeTitle ?? AppStrings.chatScopeSaint;
    return c.scope == ChatScopeKind.saint
        ? '${AppStrings.chatScopeSaintOf} $saint'
        : '${AppStrings.chatScopeSectionOf} $saint';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(AppIcons.library, size: 16),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              AppStrings.chatBookOnly,
              key: Key('book-only-indicator'),
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        if (state.conversation != null)
          Row(children: [
            Expanded(
              child: Text(
                '${AppStrings.chatScopeLabel}: ${_scopeText()}',
                key: const Key('scope-chip'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              key: const Key('scope-change'),
              onPressed: () => showScopeSheet(context),
              child: const Text(AppStrings.chatScopeChange),
            ),
          ]),
      ]),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.state, required this.onRetry});

  final ConversationState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kind = state.errorKind ?? ChatErrorKind.server;
    // A missing configuration cannot be fixed by retrying.
    final canRetry = kind != ChatErrorKind.notConfigured;
    return Container(
      key: const Key('send-error'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          errorText(kind, state.retryAfterSeconds),
          key: Key('send-error-${kind.name}'),
          style: TextStyle(color: scheme.onErrorContainer),
        ),
        if (kind != ChatErrorKind.storage)
          const Text(AppStrings.chatSendFailedKept,
              style: TextStyle(fontSize: 12)),
        Row(children: [
          if (canRetry)
            TextButton(
              key: const Key('send-retry'),
              onPressed: onRetry,
              child: const Text(AppStrings.chatSendRetry),
            ),
          TextButton(
            key: const Key('send-error-dismiss'),
            onPressed: () => context.read<ConversationCubit>().dismissError(),
            child: const Text(AppStrings.chatDismiss),
          ),
        ]),
      ]),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text, required this.id});

  final String text;
  final String id;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      // In RTL, "start" is the right side: the user's messages.
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        key: Key('message-$id'),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: TextStyle(color: scheme.onPrimary)),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message, required this.question});

  final ChatMessage message;
  final String question;

  @override
  Widget build(BuildContext context) {
    final stored = decodeStoredReply(message.metaJson);
    final reply = stored?.reply;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        key: Key('message-${message.id}'),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.goldSoft),
          borderRadius: BorderRadius.circular(16),
        ),
        child: switch (reply) {
          AnsweredReply r => _Answered(
              reply: r,
              messageId: message.id,
              question: question,
              contentVersion: stored?.contentVersion,
            ),
          RefusedReply r => _Refused(reply: r),
          SafetyReply r => _Safety(reply: r),
          null => Text(message.content),
        },
      ),
    );
  }
}

class _Answered extends StatelessWidget {
  const _Answered({
    required this.reply,
    required this.messageId,
    required this.question,
    required this.contentVersion,
  });

  final AnsweredReply reply;
  final String messageId;
  final String question;
  final int? contentVersion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final b in reply.blocks) _Block(block: b),
      if (reply.pastoralNote != null)
        Container(
          key: const Key('pastoral-note'),
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(reply.pastoralNote!,
              style: Theme.of(context).textTheme.bodySmall),
        ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: Key('report-$messageId'),
          icon: const Icon(AppIcons.report, size: 16),
          label: const Text(AppStrings.chatReportAnswer),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ReportScreen(
              answerText: reply.plainText,
              question: question,
              citedParagraphIds: reply.citedParagraphIds,
              contentVersion: contentVersion,
              provider: reply.provider,
              model: reply.model,
            ),
          )),
        ),
      ),
    ]);
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.block});

  final AnswerBlock block;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, key) = switch (block.type) {
      BlockType.quotation => (AppStrings.chatBlockQuotation, 'block-quotation'),
      BlockType.paraphrase => (AppStrings.chatBlockParaphrase, 'block-paraphrase'),
      BlockType.inference => (AppStrings.chatBlockInference, 'block-inference'),
    };
    final quote = block.type == BlockType.quotation;
    final refs = <String, SourceRef>{
      for (final r in block.references) r.paragraphId: r,
    };
    return Container(
      key: Key(key),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: quote ? AppTheme.parchmentDeep : null,
        border: BorderDirectional(
          start: BorderSide(
            color: quote ? AppTheme.gold : scheme.outlineVariant,
            width: 3,
          ),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.secondary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          block.text,
          style: quote
              ? const TextStyle(fontFamily: AppTheme.bookFontFamily, fontSize: 18, height: 1.9)
              : null,
        ),
        if (refs.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final r in refs.values) _RefChip(ref: r),
          ]),
        ],
      ]),
    );
  }
}

class _RefChip extends StatelessWidget {
  const _RefChip({required this.ref});

  final SourceRef ref;

  @override
  Widget build(BuildContext context) {
    final page = ref.page == null ? '' : ' · ${AppStrings.chatPageShort} ${ref.page}';
    return ActionChip(
      key: Key('ref-${ref.paragraphId}'),
      avatar: const Icon(AppIcons.library, size: 14),
      label: Text('${ref.saintTitle} › ${ref.sectionTitle}$page'),
      onPressed: () => context.push(AppRoutes.section(
        ref.saintId,
        ref.sectionId,
        paragraphId: ref.paragraphId,
      )),
    );
  }
}

class _Refused extends StatelessWidget {
  const _Refused({required this.reply});

  final RefusedReply reply;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(reply.message, key: const Key('refused-message')),
      if (reply.reason == 'out_of_scope_saint')
        TextButton(
          key: const Key('refused-ask-book'),
          onPressed: () => startConversation(context, ChatScopeKind.book),
          child: const Text(AppStrings.chatRefusedAskBook),
        ),
    ]);
  }
}

class _Safety extends StatelessWidget {
  const _Safety({required this.reply});

  final SafetyReply reply;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('safety-card'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppStrings.chatSafetyTitle,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(reply.message),
      ]),
    );
  }
}
