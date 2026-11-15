import 'package:go_router/go_router.dart';

import '../../core/content/asset_content_source.dart';
import '../../core/content/preview/content_preview_screen.dart';
import '../../core/screens/home_screen.dart';
import '../../core/screens/placeholder_screen.dart';
import '../strings.dart';

/// Route paths. Real screens replace placeholders in later tasks.
class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const library = '/library';
  static const search = '/search';
  static const bookmarks = '/bookmarks';
  static const chat = '/chat';
  static const settings = '/settings';
  static const contentPreview = '/content-preview';

  static const all = [
    home,
    library,
    search,
    bookmarks,
    chat,
    settings,
    contentPreview,
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
        builder: (context, state) => const PlaceholderScreen(
          screenKey: 'library-screen',
          title: AppStrings.library,
        ),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const PlaceholderScreen(
          screenKey: 'search-screen',
          title: AppStrings.search,
        ),
      ),
      GoRoute(
        path: AppRoutes.bookmarks,
        builder: (context, state) => const PlaceholderScreen(
          screenKey: 'bookmarks-screen',
          title: AppStrings.bookmarks,
        ),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) => const PlaceholderScreen(
          screenKey: 'chat-screen',
          title: AppStrings.chat,
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
        path: AppRoutes.settings,
        builder: (context, state) => const PlaceholderScreen(
          screenKey: 'settings-screen',
          title: AppStrings.settings,
        ),
      ),
    ],
  );
}
