import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/strings.dart';
import '../../../core/widgets/status_views.dart';
import '../data/library_repository.dart';
import 'library_cubit.dart';
import 'load_status.dart';

class SaintsListScreen extends StatelessWidget {
  const SaintsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LibraryCubit(context.read<LibraryRepository>())..load(),
      child: const _SaintsListView(),
    );
  }
}

class _SaintsListView extends StatelessWidget {
  const _SaintsListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('saints-list-screen'),
      appBar: AppBar(title: const Text(AppStrings.saintsList)),
      body: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          switch (state.status) {
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.error:
              return ErrorView(
                details: state.error ?? AppStrings.loadFailed,
                onRetry: () => context.read<LibraryCubit>().load(),
              );
            case LoadStatus.empty:
              return const EmptyView(message: AppStrings.emptySaints);
            case LoadStatus.loaded:
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final e in state.saints)
                    Card(
                      child: ListTile(
                        key: Key('saint-tile-${e.id}'),
                        title: Text(e.title),
                        subtitle: Text(
                          '${e.sectionCount} ${AppStrings.sectionsWord} - '
                          '${e.paragraphCount} ${AppStrings.paragraphsWord}',
                        ),
                        onTap: () => context.push(AppRoutes.saint(e.id)),
                      ),
                    ),
                ],
              );
          }
        },
      ),
    );
  }
}
