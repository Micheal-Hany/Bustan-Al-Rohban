import 'package:flutter/material.dart';

import '../../../app/strings.dart';
import '../domain/editorial.dart';

/// Editorial text (not from the book). Distinguished by icon, label, border
/// and background, so it never relies on colour alone.
class EditorialCard extends StatelessWidget {
  const EditorialCard({super.key, required this.addition});

  final EditorialAddition addition;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        border: Border.all(color: scheme.tertiary, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.edit_note, color: scheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.editorialLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            addition.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(addition.body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
