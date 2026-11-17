import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/strings.dart';
import '../../../core/widgets/status_views.dart';
import '../../reader/progress/resume_card.dart';
import '../data/library_repository.dart';
import 'library_cubit.dart';
import 'load_status.dart';

/// Library home: the books in the library (one book in Version 1).
class LibraryHomeScreen extends StatelessWidget {
  const LibraryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LibraryCubit(context.read<LibraryRepository>())..load(),
      child: const _LibraryHomeView(),
    );
  }
}

class _LibraryHomeView extends StatelessWidget {
  const _LibraryHomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('library-screen'),
      appBar: AppBar(title: const Text(AppStrings.library)),
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
              return const EmptyView(message: AppStrings.emptyLibrary);
            case LoadStatus.loaded:
              final manifest = state.manifest!;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const ResumeCard(),
                  Card(
                    child: ListTile(
                      key: const Key('book-tile'),
                      leading: const Icon(Icons.menu_book),
                      title: Text(manifest.title),
                      subtitle: Text(
                        '${state.saints.length} ${AppStrings.saintsWord}',
                      ),
                      onTap: () => context.push(AppRoutes.libraryBook),
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
