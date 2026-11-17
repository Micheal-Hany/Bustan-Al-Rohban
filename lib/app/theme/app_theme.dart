import 'package:flutter/material.dart';

/// Arabic-first theme: warm parchment surfaces, deep monastic brown and
/// muted gold. UI font Tajawal; book text uses [bookFontFamily] (Amiri).
/// Dark mode is added in Task 12b.
class AppTheme {
  const AppTheme._();

  static const fontFamily = 'Tajawal';
  static const bookFontFamily = 'Amiri';

  static const brown = Color(0xFF5B3A29);
  static const gold = Color(0xFFB8893B);
  static const parchment = Color(0xFFFAF4E8);
  static const parchmentDeep = Color(0xFFF1E6D0);
  static const ink = Color(0xFF2B1D14);
  static const goldSoft = Color(0x59B8893B); // gold @ 35%
  static const goldMid = Color(0x80B8893B); // gold @ 50%

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brown,
      brightness: Brightness.light,
    ).copyWith(
      primary: brown,
      onPrimary: Colors.white,
      secondary: gold,
      surface: parchment,
      onSurface: ink,
      surfaceContainerHighest: parchmentDeep,
      tertiaryContainer: const Color(0xFFF6E7C1),
      onTertiaryContainer: const Color(0xFF4A3410),
      tertiary: gold,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = base.textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: ink,
      displayColor: ink,
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
    return base.copyWith(
      scaffoldBackgroundColor: parchment,
      textTheme: text.copyWith(
        bodyLarge: (text.bodyLarge ?? const TextStyle()).copyWith(height: 1.8),
        bodyMedium:
            (text.bodyMedium ?? const TextStyle()).copyWith(height: 1.8),
        titleLarge: (text.titleLarge ?? const TextStyle())
            .copyWith(fontWeight: FontWeight.w700),
        titleMedium: (text.titleMedium ?? const TextStyle())
            .copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: parchment,
        foregroundColor: brown,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: brown,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: shape.copyWith(
          side: BorderSide(color: goldSoft),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: brown,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: goldMid),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: goldMid),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brown, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brown,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brown,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: goldSoft),
    );
  }
}
