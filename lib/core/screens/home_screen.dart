import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/strings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <({String key, String title, IconData icon, String path})>[
      (
        key: 'nav-library',
        title: AppStrings.library,
        icon: Icons.menu_book,
        path: AppRoutes.library
      ),
      (
        key: 'nav-search',
        title: AppStrings.search,
        icon: Icons.search,
        path: AppRoutes.search
      ),
      (
        key: 'nav-bookmarks',
        title: AppStrings.bookmarks,
        icon: Icons.bookmark,
        path: AppRoutes.bookmarks
      ),
      (
        key: 'nav-chat',
        title: AppStrings.chat,
        icon: Icons.chat_bubble_outline,
        path: AppRoutes.chat
      ),
      (
        key: 'nav-settings',
        title: AppStrings.settings,
        icon: Icons.settings,
        path: AppRoutes.settings
      ),
    ];

    return Scaffold(
      key: const Key('home-screen'),
      appBar: AppBar(title: const Text(AppStrings.appTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppStrings.homeSubtitle,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          for (final e in entries)
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
    );
  }
}
