import 'package:flutter/services.dart' show rootBundle;

import 'content_source.dart';

/// Reads content from the app's asset bundle. Works fully offline.
class AssetContentSource implements ContentSource {
  const AssetContentSource(this.root);

  /// Asset folder, e.g. `assets/content`.
  final String root;

  @override
  Future<String> readString(String relativePath) =>
      rootBundle.loadString('$root/$relativePath');
}
