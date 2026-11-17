import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../library/data/library_repository.dart';
import '../../library/presentation/load_status.dart';
import '../domain/bookmark.dart';
import 'bookmarks_cubit.dart';

/// A bookmark plus where its paragraph is NOW in the content. [location] is
/// null when the paragraph no longer exists (unavailable after an update).
class BookmarkView {
  const BookmarkView({required this.bookmark, required this.location});

  final Bookmark bookmark;
  final ParagraphLocation? location;

  bool get isAvailable => location != null;
}

class BookmarkListState {
  const BookmarkListState({
    required this.status,
    this.views = const [],
    this.error,
  });

  final LoadStatus status;
  final List<BookmarkView> views;
  final String? error;
}

/// Resolves the app-wide bookmarks to current content locations, and follows
/// changes made elsewhere (for example from the reader).
class BookmarkListCubit extends Cubit<BookmarkListState> {
  BookmarkListCubit(this._source, this._library)
      : super(const BookmarkListState(status: LoadStatus.loading)) {
    _sub = _source.stream.listen(_resolve);
    _resolve(_source.state);
  }

  final BookmarksCubit _source;
  final LibraryRepository _library;
  late final StreamSubscription<BookmarksState> _sub;
  int _seq = 0;

  Future<void> reload() => _source.load();

  Future<void> remove(String id) => _source.remove(id);

  Future<void> _resolve(BookmarksState s) async {
    final seq = ++_seq;
    if (s.status == BookmarksStatus.loading) {
      emit(const BookmarkListState(status: LoadStatus.loading));
      return;
    }
    if (s.status == BookmarksStatus.error && s.items.isEmpty) {
      emit(BookmarkListState(status: LoadStatus.error, error: s.error));
      return;
    }
    try {
      final views = <BookmarkView>[];
      for (final b in s.items) {
        final loc = await _library.locate(b.paragraphId, saintHint: b.saintId);
        views.add(BookmarkView(bookmark: b, location: loc));
      }
      if (isClosed || seq != _seq) return;
      emit(BookmarkListState(
        status: views.isEmpty ? LoadStatus.empty : LoadStatus.loaded,
        views: views,
      ));
    } catch (e) {
      if (isClosed || seq != _seq) return;
      emit(BookmarkListState(status: LoadStatus.error, error: describeError(e)));
    }
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
