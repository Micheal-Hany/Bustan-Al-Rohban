import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/strings.dart';
import '../domain/reading_prefs.dart';
import 'reading_prefs_cubit.dart';
import '../../../app/theme/app_icons.dart';

/// Settings. Version 1 has reading preferences; dark mode comes in Task 12b.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _spacingLabels = {
    LineSpacing.compact: AppStrings.lineSpacingCompact,
    LineSpacing.normal: AppStrings.lineSpacingNormal,
    LineSpacing.relaxed: AppStrings.lineSpacingRelaxed,
  };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReadingPrefsCubit>();
    return BlocConsumer<ReadingPrefsCubit, ReadingPrefsState>(
      listenWhen: (previous, current) => current.error != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.error!)));
      },
      builder: (context, state) {
        final prefs = state.prefs;
        final theme = Theme.of(context);
        final base = theme.textTheme.bodyLarge ?? const TextStyle();
        return Scaffold(
          key: const Key('settings-screen'),
          appBar: AppBar(title: const Text(AppStrings.settings)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(AppStrings.readingSection,
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(AppStrings.fontSizeLabel,
                  style: theme.textTheme.labelLarge),
              Row(children: [
                IconButton(
                  key: const Key('settings-text-smaller'),
                  tooltip: AppStrings.textSmaller,
                  icon: const Icon(AppIcons.textSmaller),
                  onPressed: prefs.canDecrease ? cubit.smaller : null,
                ),
                Text(
                  '${(prefs.textScale * 100).round()}%',
                  key: const Key('settings-text-scale-label'),
                  textDirection: TextDirection.ltr,
                ),
                IconButton(
                  key: const Key('settings-text-larger'),
                  tooltip: AppStrings.textLarger,
                  icon: const Icon(AppIcons.textLarger),
                  onPressed: prefs.canIncrease ? cubit.larger : null,
                ),
                const Spacer(),
                TextButton(
                  key: const Key('settings-text-reset'),
                  onPressed: prefs.textScale == ReadingPrefs.defaultTextScale
                      ? null
                      : cubit.resetTextScale,
                  child: const Text(AppStrings.resetSize),
                ),
              ]),
              const SizedBox(height: 8),
              Text(AppStrings.lineSpacingLabel,
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final s in LineSpacing.values)
                  ChoiceChip(
                    key: Key('settings-line-${s.name}'),
                    label: Text(_spacingLabels[s]!),
                    selected: prefs.lineSpacing == s,
                    onSelected: (_) => cubit.setLineSpacing(s),
                  ),
              ]),
              const SizedBox(height: 16),
              Text(AppStrings.previewLabel, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppStrings.previewSample,
                  key: const Key('settings-preview'),
                  style: base.copyWith(
                    fontSize: 18 * prefs.textScale,
                    height: prefs.lineSpacing.height,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                key: const Key('settings-reset-all'),
                onPressed: prefs == ReadingPrefs.defaults ? null : cubit.resetAll,
                child: const Text(AppStrings.resetAll),
              ),
            ],
          ),
        );
      },
    );
  }
}
