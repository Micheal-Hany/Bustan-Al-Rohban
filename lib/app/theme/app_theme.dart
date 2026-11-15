import 'package:flutter/material.dart';

/// Arabic RTL-friendly theme. Dark mode is added in Task 12b.
class AppTheme {
  const AppTheme._();

  /// Bundled font family (see assets/fonts/README.md). Falls back to the
  /// device font until the font files are added.
  static const fontFamily = 'NotoNaskhArabic';

  static const _seed = Color(0xFF6B3E26);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _seed),
    );
    final text = base.textTheme.apply(fontFamily: fontFamily);
    return base.copyWith(
      textTheme: text.copyWith(
        bodyLarge: (text.bodyLarge ?? const TextStyle()).copyWith(height: 1.8),
        bodyMedium:
            (text.bodyMedium ?? const TextStyle()).copyWith(height: 1.8),
      ),
    );
  }
}
