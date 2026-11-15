import 'package:flutter/material.dart';

import '../../app/strings.dart';

/// Temporary screen for features built in later tasks.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.screenKey,
    required this.title,
  });

  final String screenKey;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key(screenKey),
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text(AppStrings.underConstruction)),
    );
  }
}
