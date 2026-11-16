import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/strings.dart';
import '../../../core/content/content_models.dart';
import '../../../core/widgets/status_views.dart';
import '../data/library_repository.dart';
import 'load_status.dart';
import 'saint_cubit.dart';

/// Temporary target for opening a section. Replaced by the reader in Task 3.
class SectionPlaceholderScreen extends StatelessWidget {
  const SectionPlaceholderScreen({
    super.key,
    required this.saintId,
    required this.sectionId,
  });

  final String saintId;
  final String sectionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SaintCubit(context.read<LibraryRepository>(), saintId)..load(),
      child: _SectionView(sectionId: sectionId),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({required this.sectionId});

  final String sectionId;

  Section? _find(Saint saint) {
    for (final s in saint.sections) {
      if (s.id == sectionId) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SaintCubit, SaintState>(
      builder: (context, state) {
        final saint = state.saint;
        final section = saint == null ? null : _find(saint);
        return Scaffold(
          key: const Key('section-screen'),
          appBar: AppBar(title: Text(section?.title ?? AppStrings.library)),
          body: _body(context, state, section),
        );
      },
    );
  }

  Widget _body(BuildContext context, SaintState state, Section? section) {
    switch (state.status) {
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          details: state.error ?? AppStrings.loadFailed,
          onRetry: () => context.read<SaintCubit>().load(),
        );
      case LoadStatus.empty:
      case LoadStatus.loaded:
        if (section == null) {
          return const EmptyView(message: AppStrings.notFound);
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${AppStrings.readerComingSoon}\n'
              '(${section.paragraphs.length} ${AppStrings.paragraphsWord})',
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }
}
