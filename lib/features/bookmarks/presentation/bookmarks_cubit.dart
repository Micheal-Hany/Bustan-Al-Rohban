import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/strings.dart';
import '../domain/bookmark.dart';
import '../domain/bookmark_store.dart';

enum BookmarksStatus { loading, loaded, error }

class BookmarksState {
  const BookmarksState({
    required this.status,
    this.items = const [],
    this.error,
  });

  final BookmarksStatus status;

  /// Newest first.
  final List<Bookmark> items;

  /// Set when the last action failed; [items] is the last known good list.
  final String? error;

  bool isBookmarked(String paragraphId) =>
      items.any((b) => b.paragraphId == paragraphId && b.offset == 0);

  Bookmark? forParagraph(String paragraphId) {
    for (final b in items) {
      if (b.paragraphId == paragraphId && b.offset == 0) return b;
    }
    return null;
  }
}

/// App-wide bookmarks: shared by the reader (toggle) and the bookmarks screen.
class BookmarksCubit extends Cubit<BookmarksState> {
  BookmarksCubit(this._store)
      : super(const BookmarksState(status: BookmarksStatus.loading));

  final BookmarkStore _store;

  Future<void> load() async {
    try {
      final items = await _store.all();
      if (isClosed) return;
      emit(BookmarksState(status: BookmarksStatus.loaded, items: items));
    } catch (_) {
      if (isClosed) return;
      emit(BookmarksState(
        status: BookmarksStatus.error,
        items: state.items,
        error: AppStrings.bookmarkLoadFailed,
      ));
    }
  }

  /// Adds the bookmark, or removes it when the paragraph is already
  /// bookmarked.
  Future<void> toggle({
    required String saintId,
    required String sectionId,
    required String paragraphId,
    required int contentVersion,
  }) async {
    try {
      final existing = state.forParagraph(paragraphId);
      if (existing != null) {
        await _store.remove(existing.id);
      } else {
        await _store.add(
          saintId: saintId,
          sectionId: sectionId,
          paragraphId: paragraphId,
          contentVersion: contentVersion,
        );
      }
      await load();
    } catch (_) {
      if (isClosed) return;
      emit(BookmarksState(
        status: BookmarksStatus.loaded,
        items: state.items,
        error: AppStrings.bookmarkSaveFailed,
      ));
    }
  }

  Future<void> remove(String id) async {
    try {
      await _store.remove(id);
      await load();
    } catch (_) {
      if (isClosed) return;
      emit(BookmarksState(
        status: BookmarksStatus.loaded,
        items: state.items,
        error: AppStrings.bookmarkSaveFailed,
      ));
    }
  }
}
