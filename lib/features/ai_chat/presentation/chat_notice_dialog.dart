import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/strings.dart';

/// "What is sent" notice shown once, before the first question. Returns
/// true when the user agrees to continue.
Future<bool> showChatNoticeDialog(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      key: const Key('chat-notice-dialog'),
      title: const Text(AppStrings.chatNoticeTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.chatNoticeBody),
            TextButton(
              key: const Key('chat-notice-read-more'),
              onPressed: () => context.push(AppRoutes.privacy),
              child: const Text(AppStrings.chatNoticeReadMore),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('chat-notice-cancel'),
          onPressed: () => Navigator.of(dialog).pop(false),
          child: const Text(AppStrings.chatCancel),
        ),
        FilledButton(
          key: const Key('chat-notice-accept'),
          onPressed: () => Navigator.of(dialog).pop(true),
          child: const Text(AppStrings.chatNoticeAccept),
        ),
      ],
    ),
  );
  return ok ?? false;
}
