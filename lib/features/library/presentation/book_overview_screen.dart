import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/strings.dart';
import '../../../core/widgets/status_views.dart';
import '../data/library_repository.dart';
import 'library_cubit.dart';
import 'load_status.dart';

class BookOverviewScreen extends StatelessWidget {
  const BookOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LibraryCubit(context.read<LibraryRepository>())..load(),
      child: const _BookOverviewView(),
    );
  }
}

class _BookOverviewView extends StatelessWidget {
  const _BookOverviewView();

  static const _editionLabels = {
    'title': AppStrings.editionLabel,
    'author': AppStrings.authorLabel,
    'publisher': AppStrings.publisherLabel,
    'year': AppStrings.yearLabel,
    'attribution': AppStrings.attributionLabel,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('book-overview-screen'),
      appBar: AppBar(title: const Text(AppStrings.bookOverview)),
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
            case LoadStatus.loaded:
              final manifest = state.manifest!;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (manifest.fixture)
                    Card(
                      key: const Key('fake-banner'),
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(AppStrings.fakeBanner),
                      ),
                    ),
                  Text(
                    manifest.title,
                    key: const Key('book-title'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  for (final entry in _editionLabels.entries)
                    if (manifest.edition[entry.key] != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${entry.value}: ${manifest.edition[entry.key]}',
                        ),
                      ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${AppStrings.contentVersionLabel}: '
                      '${manifest.contentVersion}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('saints-button'),
                    onPressed: () => context.push(AppRoutes.librarySaints),
                    child: Text(
                      '${AppStrings.viewSaints} (${state.saints.length})',
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
