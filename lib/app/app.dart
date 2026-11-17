import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/content/asset_content_source.dart';
import '../core/content/content_loader.dart';
import '../features/ai_chat/domain/chat_store.dart';
import '../features/audio/domain/speech_cubit.dart';
import '../features/audio/domain/tts_engine.dart';
import '../features/bookmarks/domain/bookmark_store.dart';
import '../features/bookmarks/presentation/bookmarks_cubit.dart';
import '../features/library/data/library_repository.dart';
import '../features/reader/progress/progress_cubit.dart';
import '../features/reader/progress/reading_progress.dart';
import '../features/search/data/search_repository.dart';
import '../features/settings/domain/reading_prefs.dart';
import '../features/settings/presentation/reading_prefs_cubit.dart';
import 'router/app_router.dart';
import 'strings.dart';
import 'theme/app_theme.dart';

/// Root widget. Arabic-only (RTL) in Version 1. Needs no network at startup.
class BustanApp extends StatefulWidget {
  /// [libraryRepository] is injectable for tests; by default the installed
  /// book is read from the asset bundle.
  ///
  /// [bookmarkStore], [progressStore] and [prefsStore] default to memory-only stores; the
  /// real app (`main.dart`) passes the Drift-backed ones.
  const BustanApp({
    super.key,
    this.libraryRepository,
    this.ttsEngineFactory,
    this.chatStore,
    this.bookmarkStore,
    this.progressStore,
    this.prefsStore,
  });

  final LibraryRepository? libraryRepository;

  /// Local chat history (memory-only by default; `main.dart` passes Drift).
  final ChatStore? chatStore;

  /// Creates the text-to-speech engine on first use (tests pass a fake).
  final TtsEngine Function()? ttsEngineFactory;
  final BookmarkStore? bookmarkStore;
  final ProgressStore? progressStore;
  final PrefsStore? prefsStore;

  @override
  State<BustanApp> createState() => _BustanAppState();
}

class _BustanAppState extends State<BustanApp> {
  late final GoRouter _router = createRouter();
  late final LibraryRepository _library = widget.libraryRepository ??
      LibraryRepository(
        ContentLoader(const AssetContentSource('assets/content')),
      );
  late final SearchRepository _search = SearchRepository(_library);
  late final BookmarksCubit _bookmarks =
      BookmarksCubit(widget.bookmarkStore ?? InMemoryBookmarkStore())..load();
  late final ProgressCubit _progress =
      ProgressCubit(widget.progressStore ?? InMemoryProgressStore())..load();
  late final ChatStore _chat = widget.chatStore ?? InMemoryChatStore();
  late final SpeechCubit _speech =
      SpeechCubit(widget.ttsEngineFactory ?? FlutterTtsEngine.new);
  late final ReadingPrefsCubit _prefs =
      ReadingPrefsCubit(widget.prefsStore ?? InMemoryPrefsStore())..load();

  @override
  void dispose() {
    _router.dispose();
    _bookmarks.close();
    _progress.close();
    _prefs.close();
    _speech.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LibraryRepository>.value(value: _library),
        RepositoryProvider<SearchRepository>.value(value: _search),
        RepositoryProvider<ChatStore>.value(value: _chat),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<BookmarksCubit>.value(value: _bookmarks),
          BlocProvider<ProgressCubit>.value(value: _progress),
          BlocProvider<ReadingPrefsCubit>.value(value: _prefs),
          BlocProvider<SpeechCubit>.value(value: _speech),
        ],
        child: MaterialApp.router(
          title: AppStrings.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
        ),
      ),
    );
  }
}
