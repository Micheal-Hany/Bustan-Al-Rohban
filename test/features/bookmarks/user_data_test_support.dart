import 'package:bustan_al_rohban/features/audio/domain/speech_cubit.dart';
import 'package:bustan_al_rohban/features/audio/domain/tts_engine.dart';
import 'package:bustan_al_rohban/features/bookmarks/domain/bookmark.dart';
import 'package:bustan_al_rohban/features/bookmarks/domain/bookmark_store.dart';
import 'package:bustan_al_rohban/features/bookmarks/presentation/bookmarks_cubit.dart';
import 'package:bustan_al_rohban/features/reader/progress/progress_cubit.dart';
import 'package:bustan_al_rohban/features/reader/progress/reading_progress.dart';
import 'package:bustan_al_rohban/features/settings/domain/reading_prefs.dart';
import 'package:bustan_al_rohban/features/settings/presentation/reading_prefs_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Provides the app-level bookmark and progress cubits above [child], like
/// `BustanApp` does, for tests that pump a screen directly.
Widget withUserData(
  Widget child, {
  BookmarkStore? bookmarks,
  ProgressStore? progress,
  PrefsStore? prefs,
  TtsEngine Function()? tts,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) =>
            BookmarksCubit(bookmarks ?? InMemoryBookmarkStore())..load(),
      ),
      BlocProvider(
        create: (_) =>
            ProgressCubit(progress ?? InMemoryProgressStore())..load(),
      ),
      BlocProvider(
        create: (_) => SpeechCubit(tts ?? _unusedEngine),
      ),
      BlocProvider(
        create: (_) =>
            ReadingPrefsCubit(prefs ?? InMemoryPrefsStore())..load(),
      ),
    ],
    child: child,
  );
}

TtsEngine _unusedEngine() =>
    throw StateError('Text-to-speech engine used in a test that did not set one');

/// A store whose writes (and optionally reads) can be made to fail.
class FailingBookmarkStore implements BookmarkStore {
  FailingBookmarkStore(this.inner);

  final BookmarkStore inner;
  bool failWrites = false;
  bool failReads = false;

  @override
  Future<List<Bookmark>> all() async {
    if (failReads) throw StateError('read failed');
    return inner.all();
  }

  @override
  Future<Bookmark?> find(String paragraphId, {int offset = 0}) =>
      inner.find(paragraphId, offset: offset);

  @override
  Future<Bookmark> add({
    required String saintId,
    required String sectionId,
    required String paragraphId,
    int offset = 0,
    required int contentVersion,
  }) async {
    if (failWrites) throw StateError('write failed');
    return inner.add(
      saintId: saintId,
      sectionId: sectionId,
      paragraphId: paragraphId,
      offset: offset,
      contentVersion: contentVersion,
    );
  }

  @override
  Future<bool> remove(String id) async {
    if (failWrites) throw StateError('write failed');
    return inner.remove(id);
  }
}
