import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/strings.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/content/content_models.dart';
import '../../../core/widgets/status_views.dart';
import '../../library/data/library_repository.dart';
import '../../library/presentation/load_status.dart';
import '../domain/insight.dart';
import 'insights_cubit.dart';

/// Prepared insights of one section. Visually distinct from the book text
/// (own colours, icon, label); each insight links back to its source
/// paragraphs in the original text.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({
    super.key,
    required this.saintId,
    required this.sectionId,
  });

  final String saintId;
  final String sectionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InsightsCubit(
        context.read<LibraryRepository>(),
        saintId: saintId,
        sectionId: sectionId,
      )..load(),
      child: BlocBuilder<InsightsCubit, InsightsState>(
        builder: (context, state) => Scaffold(
          key: const Key('insights-screen'),
          appBar: AppBar(
            title: Text(state.section?.title ?? AppStrings.insights),
          ),
          body: _body(context, state),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, InsightsState state) {
    switch (state.status) {
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          details: state.error ?? AppStrings.loadFailed,
          onRetry: () => context.read<InsightsCubit>().load(),
        );
      case LoadStatus.empty:
        return const EmptyView(message: AppStrings.insightsNone);
      case LoadStatus.loaded:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final i in state.insights)
              InsightCard(
                key: Key('insight-${i.id}'),
                insight: i,
                saint: state.saint!,
                section: state.section!,
              ),
            TextButton(
              key: const Key('insights-back-to-text'),
              onPressed: () => context.pop(),
              child: const Text(AppStrings.backToText),
            ),
          ],
        );
    }
  }
}

class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.insight,
    required this.saint,
    required this.section,
  });

  final Insight insight;
  final Saint saint;
  final Section section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final origin = insight.origin == InsightOrigin.aiDraft
        ? AppStrings.insightOriginAi
        : AppStrings.insightOriginHuman;
    Widget block(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              child,
            ],
          ),
        );
    Widget bullets(List<String> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final t in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $t', style: theme.textTheme.bodyMedium),
              ),
          ],
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        border: Border.all(color: scheme.tertiary, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(AppIcons.insights, color: scheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(AppStrings.insightsLabel,
                  style: theme.textTheme.labelLarge),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: [
            Chip(
              key: Key('insight-origin-${insight.id}'),
              label: Text(origin),
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              key: Key('insight-status-${insight.id}'),
              label: Text(insight.isApproved
                  ? AppStrings.insightApproved
                  : AppStrings.insightNotApproved),
              visualDensity: VisualDensity.compact,
            ),
          ]),
          block(AppStrings.insightSummary,
              Text(insight.summary, style: theme.textTheme.bodyMedium)),
          if (insight.keyPoints.isNotEmpty)
            block(AppStrings.insightKeyPoints, bullets(insight.keyPoints)),
          if (insight.spiritualLessons.isNotEmpty)
            block(AppStrings.insightLessons, bullets(insight.spiritualLessons)),
          if (insight.keywords.isNotEmpty)
            block(
              AppStrings.insightKeywords,
              Wrap(spacing: 6, children: [
                for (final k in insight.keywords) Chip(label: Text(k)),
              ]),
            ),
          block(
            AppStrings.insightSources,
            Wrap(spacing: 8, children: [
              for (final id in insight.supportingParagraphIds)
                ActionChip(
                  key: Key('insight-source-${insight.id}-$id'),
                  label: Text(_label(id)),
                  onPressed: () => context.push(AppRoutes.section(
                    saint.id,
                    section.id,
                    paragraphId: id,
                  )),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  String _label(String paragraphId) {
    final i = section.paragraphs.indexWhere((p) => p.id == paragraphId);
    return i < 0
        ? paragraphId
        : '${AppStrings.paragraphWord} ${i + 1}';
  }
}
