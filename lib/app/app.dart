import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/content/asset_content_source.dart';
import '../core/content/content_loader.dart';
import '../features/library/data/library_repository.dart';
import '../features/search/data/search_repository.dart';
import 'router/app_router.dart';
import 'strings.dart';
import 'theme/app_theme.dart';

/// Root widget. Arabic-only (RTL) in Version 1. Needs no network at startup.
class BustanApp extends StatefulWidget {
  /// [libraryRepository] is injectable for tests; by default the installed
  /// book is read from the asset bundle.
  const BustanApp({super.key, this.libraryRepository});

  final LibraryRepository? libraryRepository;

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

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LibraryRepository>.value(value: _library),
        RepositoryProvider<SearchRepository>.value(value: _search),
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
    );
  }
}
