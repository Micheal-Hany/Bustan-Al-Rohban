import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/strings.dart';
import '../../../core/search/snippet.dart';
import '../../../core/widgets/status_views.dart';
import '../data/search_repository.dart';
import 'search_cubit.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchCubit(context.read<SearchRepository>()),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    return Scaffold(
      key: const Key('search-screen'),
      appBar: AppBar(title: const Text(AppStrings.search)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const Key('search-field'),
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: AppStrings.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  key: const Key('search-clear'),
                  tooltip: AppStrings.searchClear,
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    cubit.queryChanged('');
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: cubit.queryChanged,
              onSubmitted: cubit.submit,
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) => _body(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, SearchState state) {
    switch (state.status) {
      case SearchStatus.idle:
        return const Center(
          key: Key('search-idle'),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(AppStrings.searchIdle, textAlign: TextAlign.center),
          ),
        );
      case SearchStatus.building:
        return const LoadingView();
      case SearchStatus.error:
        return ErrorView(
          details: state.error ?? AppStrings.loadFailed,
          onRetry: () => context.read<SearchCubit>().retry(),
        );
      case SearchStatus.noResults:
        return const EmptyView(message: AppStrings.searchNoResults);
      case SearchStatus.results:
        final response = state.response!;
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${response.total} ${AppStrings.searchResultsWord}',
                key: const Key('search-count'),
              ),
            ),
            for (final r in response.results) _ResultTile(result: r),
          ],
        );
    }
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});

  final SearchResultView result;

  @override
  Widget build(BuildContext context) {
    final p = result.paragraph;
    final page = p.page == null
        ? AppStrings.pagesUnknown
        : '${AppStrings.pageWord} ${p.page}';
    return Card(
      child: ListTile(
        key: Key('result-${p.paragraphId}'),
        title: Text('${result.saintTitle} › ${result.sectionTitle}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(page, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            _SnippetText(snippet: result.snippet),
          ],
        ),
        onTap: () => context.push(AppRoutes.section(
          p.saintId,
          p.sectionId,
          paragraphId: p.paragraphId,
        )),
      ),
    );
  }
}

/// Snippet from the original text. Matches are bold AND shaded, so they do
/// not rely on colour alone.
class _SnippetText extends StatelessWidget {
  const _SnippetText({required this.snippet});

  final SearchSnippet snippet;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.primaryContainer;
    final spans = <InlineSpan>[];
    if (snippet.truncatedStart) spans.add(const TextSpan(text: '… '));
    var cursor = 0;
    for (final (start, end) in snippet.highlights) {
      if (start > cursor) {
        spans.add(TextSpan(text: snippet.text.substring(cursor, start)));
      }
      spans.add(TextSpan(
        text: snippet.text.substring(start, end),
        style: TextStyle(fontWeight: FontWeight.bold, backgroundColor: bg),
      ));
      cursor = end;
    }
    if (cursor < snippet.text.length) {
      spans.add(TextSpan(text: snippet.text.substring(cursor)));
    }
    if (snippet.truncatedEnd) spans.add(const TextSpan(text: ' …'));
    return Text.rich(
      TextSpan(children: spans),
      key: const Key('result-snippet'),
    );
  }
}
