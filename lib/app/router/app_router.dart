import 'package:go_router/go_router.dart';

import '../../core/content/asset_content_source.dart';
import '../../core/content/preview/content_preview_screen.dart';
import '../../core/screens/home_screen.dart';
import '../../features/bookmarks/presentation/bookmarks_screen.dart';
import '../../features/library/presentation/book_overview_screen.dart';
import '../../spikes/tts/tts_spike_screen.dart';
import '../../features/library/presentation/library_home_screen.dart';
import '../../features/ai_chat/presentation/chat_history_screen.dart';
import '../../features/ai_chat/presentation/conversation_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/library/presentation/saint_sections_screen.dart';
import '../../features/library/presentation/saints_list_screen.dart';
import '../../features/reader/presentation/reader_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/privacy/presentation/privacy_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

/// Route paths. Real screens replace placeholders in later tasks.
class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const library = '/library';
  static const libraryBook = '/library/book';
  static const librarySaints = '/library/book/saints';
  static const search = '/search';
  static const bookmarks = '/bookmarks';
  static const chat = '/chat';
  static const settings = '/settings';
  static const privacy = '/privacy';
  static const contentPreview = '/content-preview';
  static const ttsSpike = '/spikes/tts';

  static String saint(String saintId) => '$librarySaints/$saintId';

  /// [paragraphId] opens the reader at that paragraph anchor.
  static String section(
    String saintId,
    String sectionId, {
    String? paragraphId,
  }) {
    final path = '$librarySaints/$saintId/sections/$sectionId';
    return paragraphId == null ? path : '$path?p=$paragraphId';
  }

  static String conversation(String id) => '$chat/$id';

  static String insights(String saintId, String sectionId) =>
      '$librarySaints/$saintId/sections/$sectionId/insights';

  static const all = [
    home,
    library,
    libraryBook,
    librarySaints,
    search,
    bookmarks,
    chat,
    settings,
    privacy,
    contentPreview,
    ttsSpike,
  ];
}

/// A new router per app instance (keeps tests isolated).
GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.library,
        builder: (context, state) => const LibraryHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.libraryBook,
        builder: (context, state) => const BookOverviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.librarySaints,
        builder: (context, state) => const SaintsListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.librarySaints}/:saintId',
        builder: (context, state) => SaintSectionsScreen(
          saintId: state.pathParameters['saintId']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.librarySaints}/:saintId/sections/:sectionId',
        builder: (context, state) => ReaderScreen(
          saintId: state.pathParameters['saintId']!,
          sectionId: state.pathParameters['sectionId']!,
          paragraphId: state.uri.queryParameters['p'],
        ),
      ),
      GoRoute(
        path: '${AppRoutes.librarySaints}/:saintId/sections/:sectionId/insights',
        builder: (context, state) => InsightsScreen(
          saintId: state.pathParameters['saintId']!,
          sectionId: state.pathParameters['sectionId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookmarks,
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) => const ChatHistoryScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.chat}/:conversationId',
        builder: (context, state) => ConversationScreen(
          conversationId: state.pathParameters['conversationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.contentPreview,
        builder: (context, state) => const ContentPreviewScreen(
          validSource: AssetContentSource('assets/content'),
          invalidSource: AssetContentSource('assets/content_fixtures/invalid'),
        ),
      ),
      GoRoute(
        path: AppRoutes.ttsSpike,
        builder: (context, state) => const TtsSpikeScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
