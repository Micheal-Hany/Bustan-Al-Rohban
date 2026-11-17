import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/strings.dart';
import '../../../core/widgets/status_views.dart';
import '../../library/data/library_repository.dart';
import '../../library/presentation/load_status.dart';
import 'bookmark_list_cubit.dart';
import 'bookmarks_cubit.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookmarkListCubit(
        context.read<BookmarksCubit>(),
        context.read<LibraryRepository>(),
      ),
      child: const _BookmarksView(),
    );
  }
}

class _BookmarksView extends StatelessWidget {
  const _BookmarksView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('bookmarks-screen'),
      appBar: AppBar(title: const Text(AppStrings.bookmarks)),
      body: BlocBuilder<BookmarkListCubit, BookmarkListState>(
        builder: (context, state) {
          switch (state.status) {
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.error:
              return ErrorView(
                details: state.error ?? AppStrings.loadFailed,
                onRetry: () => context.read<BookmarkListCubit>().reload(),
              );
            case LoadStatus.empty:
              return const EmptyView(message: AppStrings.bookmarksEmpty);
            case LoadStatus.loaded:
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final v in state.views) _BookmarkTile(view: v),
                ],
              );
          }
        },
      ),
    );
  }
}

String _preview(String text) {
  final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return flat.length <= 120 ? flat : '${flat.substring(0, 120)}…';
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({required this.view});

  final BookmarkView view;

  @override
  Widget build(BuildContext context) {
    final b = view.bookmark;
    final loc = view.location;
    final delete = IconButton(
      key: Key('bookmark-delete-${b.id}'),
      tooltip: AppStrings.deleteBookmark,
      icon: const Icon(Icons.delete_outline),
      onPressed: () => context.read<BookmarkListCubit>().remove(b.id),
    );
    if (loc == null) {
      return Card(
        child: ListTile(
          key: Key('bookmark-tile-${b.id}'),
          leading: const Icon(Icons.bookmark_remove_outlined),
          title: const Text(AppStrings.bookmarkUnavailable),
          trailing: delete,
        ),
      );
    }
    final page = loc.paragraph.page == null
        ? AppStrings.pagesUnknown
        : '${AppStrings.pageWord} ${loc.paragraph.page}';
    return Card(
      child: ListTile(
        key: Key('bookmark-tile-${b.id}'),
        leading: const Icon(Icons.bookmark),
        title: Text('${loc.saint.title} › ${loc.section.title}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(page, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(_preview(loc.paragraph.text)),
          ],
        ),
        trailing: delete,
        onTap: () => context.push(AppRoutes.section(
          loc.saint.id,
          loc.section.id,
          paragraphId: loc.paragraph.id,
        )),
      ),
    );
  }
}
