import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/strings.dart';
import '../../../core/content/content_models.dart';
import '../../library/data/library_repository.dart';
import '../domain/chat_models.dart';
import '../domain/chat_store.dart';

/// Creates a conversation with the chosen scope and opens it in place of the
/// current one. The scope of an existing conversation never changes silently.
Future<void> startConversation(
  BuildContext context,
  ChatScopeKind scope, {
  String? saintId,
}) async {
  final store = context.read<ChatStore>();
  final router = GoRouter.of(context);
  final c = await store.createConversation(scope: scope, saintId: saintId);
  router.pushReplacement(AppRoutes.conversation(c.id));
}

/// Explicit scope change: pick the whole book or one saint.
Future<void> showScopeSheet(BuildContext context) {
  final library = context.read<LibraryRepository>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.7,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(AppStrings.chatScopeChangeNote,
                key: Key('scope-change-note')),
          ),
          ListTile(
            key: const Key('scope-book'),
            title: const Text(AppStrings.chatScopeBookFull),
            onTap: () async {
              Navigator.of(sheet).pop();
              await startConversation(context, ChatScopeKind.book);
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(AppStrings.chatScopeChooseSaint),
          ),
          Expanded(
            child: FutureBuilder<List<SaintEntry>>(
              future: library.saints(),
              builder: (context, snap) {
                final saints = snap.data;
                if (saints == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(children: [
                  for (final s in saints)
                    ListTile(
                      key: Key('scope-saint-${s.id}'),
                      title: Text(s.title),
                      onTap: () async {
                        Navigator.of(sheet).pop();
                        await startConversation(
                          context,
                          ChatScopeKind.saint,
                          saintId: s.id,
                        );
                      },
                    ),
                ]);
              },
            ),
          ),
        ]),
      ),
    ),
  );
}
