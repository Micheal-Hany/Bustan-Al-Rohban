import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/strings.dart';
import '../content_models.dart';
import '../content_source.dart';
import 'content_preview_cubit.dart';

/// Debug screen: shows the installed content, FAKE labels, warnings, and lets
/// you load an intentionally invalid fixture to see validation errors.
class ContentPreviewScreen extends StatelessWidget {
  const ContentPreviewScreen({
    super.key,
    required this.validSource,
    required this.invalidSource,
  });

  final ContentSource validSource;
  final ContentSource invalidSource;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ContentPreviewCubit(
        validSource: validSource,
        invalidSource: invalidSource,
      )..loadValid(),
      child: const _PreviewView(),
    );
  }
}

class _PreviewView extends StatelessWidget {
  const _PreviewView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ContentPreviewCubit>();
    return Scaffold(
      key: const Key('content-preview-screen'),
      appBar: AppBar(title: const Text(AppStrings.contentPreview)),
      body: BlocBuilder<ContentPreviewCubit, ContentPreviewState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.tonal(
                    key: const Key('load-valid'),
                    onPressed: cubit.loadValid,
                    child: const Text(AppStrings.reloadValid),
                  ),
                  FilledButton.tonal(
                    key: const Key('load-invalid'),
                    onPressed: cubit.loadInvalid,
                    child: const Text(AppStrings.loadInvalid),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              switch (state.status) {
                PreviewStatus.loading => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                PreviewStatus.failed => _Failed(state: state),
                PreviewStatus.loaded => _Loaded(state: state),
              },
            ],
          );
        },
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.state});

  final ContentPreviewState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('content-error'),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.contentInvalid,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < state.issues.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${state.issues[i].isError ? 'خطأ' : 'تحذير'} '
                  '(${state.issues[i].code}): ${state.issues[i].location} '
                  '- ${state.issues[i].message}',
                  key: Key('issue-$i'),
                  textDirection: TextDirection.ltr,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});

  final ContentPreviewState state;

  @override
  Widget build(BuildContext context) {
    final book = state.book!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (book.manifest.fixture)
          Card(
            key: const Key('fake-banner'),
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(AppStrings.fakeBanner),
            ),
          ),
        Text(
          '${AppStrings.saintsCount}: ${book.saints.length} - '
          '${AppStrings.warningsCount}: ${state.issues.length}',
          key: const Key('content-summary'),
        ),
        const SizedBox(height: 8),
        for (final saint in book.saints) _SaintTile(saint: saint),
      ],
    );
  }
}

class _SaintTile extends StatelessWidget {
  const _SaintTile({required this.saint});

  final Saint saint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        key: Key('saint-${saint.id}'),
        title: Text(saint.title),
        subtitle: Text(
          '${saint.sections.length} ${AppStrings.sectionsWord} - '
          '${saint.paragraphCount} ${AppStrings.paragraphsWord}',
        ),
        children: [
          for (final section in saint.sections)
            ListTile(
              key: Key('section-${section.id}'),
              title: Text(section.title),
              subtitle: Text(
                '${section.paragraphs.length} ${AppStrings.paragraphsWord}'
                ' - ${_pages(section)}',
              ),
            ),
        ],
      ),
    );
  }

  String _pages(Section s) {
    if (s.pageStart == null || s.pageEnd == null) {
      return AppStrings.pagesUnknown;
    }
    return s.pageStart == s.pageEnd
        ? '${AppStrings.pageWord} ${s.pageStart}'
        : '${AppStrings.pageWord} ${s.pageStart}-${s.pageEnd}';
  }
}
