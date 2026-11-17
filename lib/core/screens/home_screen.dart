import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/strings.dart';
import '../../app/theme/app_icons.dart';
import '../../app/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final main = <({String key, String title, IconData icon, String path})>[
      (
        key: 'nav-library',
        title: AppStrings.library,
        icon: AppIcons.library,
        path: AppRoutes.library
      ),
      (
        key: 'nav-search',
        title: AppStrings.search,
        icon: AppIcons.search,
        path: AppRoutes.search
      ),
      (
        key: 'nav-bookmarks',
        title: AppStrings.bookmarks,
        icon: AppIcons.bookmarkOn,
        path: AppRoutes.bookmarks
      ),
      (
        key: 'nav-chat',
        title: AppStrings.chat,
        icon: AppIcons.chat,
        path: AppRoutes.chat
      ),
      (
        key: 'nav-settings',
        title: AppStrings.settings,
        icon: AppIcons.settings,
        path: AppRoutes.settings
      ),
    ];
    final debug = <({String key, String title, IconData icon, String path})>[
      if (kDebugMode)
        (
          key: 'nav-content-preview',
          title: AppStrings.contentPreview,
          icon: AppIcons.preview,
          path: AppRoutes.contentPreview
        ),
      if (kDebugMode)
        (
          key: 'nav-tts-spike',
          title: AppStrings.ttsSpike,
          icon: AppIcons.voice,
          path: AppRoutes.ttsSpike
        ),
    ];

    return Scaffold(
      key: const Key('home-screen'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const _Hero(),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.15,
              children: [
                for (final e in main)
                  _FeatureTile(
                    key: Key(e.key),
                    title: e.title,
                    icon: e.icon,
                    onTap: () => context.push(e.path),
                  ),
              ],
            ),
            for (final e in debug)
              Card(
                child: ListTile(
                  key: Key(e.key),
                  leading: Icon(e.icon),
                  title: Text(e.title),
                  onTap: () => context.push(e.path),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF7A4B32), AppTheme.brown, Color(0xFF3E2619)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D5B3A29),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(AppIcons.library, color: AppTheme.gold, size: 40),
          SizedBox(height: 12),
          Text(
            AppStrings.appTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.bookFontFamily,
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          SizedBox(height: 8),
          Text(
            AppStrings.homeSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 15,
              color: Color(0xD9FFFFFF),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppTheme.goldSoft),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.parchmentDeep,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.brown, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.brown),
            ),
          ],
        ),
      ),
    );
  }
}
