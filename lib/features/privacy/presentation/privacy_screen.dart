import 'package:flutter/material.dart';

import '../../../app/strings.dart';
import '../domain/privacy_text.dart';

/// The privacy notice: reachable from Settings and from the chat list, and
/// readable offline.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('privacy-screen'),
      appBar: AppBar(title: const Text(AppStrings.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(AppStrings.privacyIntro),
          const SizedBox(height: 16),
          for (final s in privacySections) ...[
            Text(s.title,
                key: Key('privacy-title-${s.id}'),
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(s.body, key: Key('privacy-body-${s.id}')),
            const SizedBox(height: 16),
          ],
          if (privacyContact.isNotEmpty) ...[
            Text(AppStrings.privacyContactLabel,
                style: theme.textTheme.titleMedium),
            Text(privacyContact, key: const Key('privacy-contact')),
          ],
        ],
      ),
    );
  }
}
