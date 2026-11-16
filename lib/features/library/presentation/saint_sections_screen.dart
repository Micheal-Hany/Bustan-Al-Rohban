import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/strings.dart';
import '../../../core/widgets/status_views.dart';
import '../data/library_repository.dart';
import 'load_status.dart';
import 'page_label.dart';
import 'saint_cubit.dart';

/// Sections of one saint. The saint file is loaded on demand.
class SaintSectionsScreen extends StatelessWidget {
  const SaintSectionsScreen({super.key, required this.saintId});

  final String saintId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SaintCubit(context.read<LibraryRepository>(), saintId)..load(),
      child: const _SectionsView(),
    );
  }
}

class _SectionsView extends StatelessWidget {
  const _SectionsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SaintCubit, SaintState>(
      builder: (context, state) {
        final saint = state.saint;
        return Scaffold(
          key: const Key('sections-screen'),
          appBar: AppBar(title: Text(saint?.title ?? AppStrings.sectionsList)),
          body: _body(context, state),
        );
      },
    );
  }

  Widget _body(BuildContext context, SaintState state) {
    switch (state.status) {
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          details: state.error ?? AppStrings.loadFailed,
          onRetry: () => context.read<SaintCubit>().load(),
        );
      case LoadStatus.empty:
        return const EmptyView(message: AppStrings.emptySections);
      case LoadStatus.loaded:
        final saint = state.saint!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (saint.aliases.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${AppStrings.aliasesLabel}: ${saint.aliases.join('، ')}',
                ),
              ),
            for (final section in saint.sections)
              Card(
                child: ListTile(
                  key: Key('section-tile-${section.id}'),
                  title: Text(section.title),
                  subtitle: Text(
                    '${section.paragraphs.length} ${AppStrings.paragraphsWord}'
                    ' - ${pageLabel(section)}',
                  ),
                  onTap: () =>
                      context.push(AppRoutes.section(saint.id, section.id)),
                ),
              ),
          ],
        );
    }
  }
}
