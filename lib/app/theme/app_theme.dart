import 'package:flutter/material.dart';

/// App colors that [ColorScheme] has no slot for. Widgets read them with
/// [BustanColors.of] so light and dark mode both work. Falls back to the
/// light values when a test pumps a plain MaterialApp.
@immutable
class BustanColors extends ThemeExtension<BustanColors> {
  const BustanColors({
    required this.card,
    required this.border,
    required this.quoteSurface,
    required this.ink,
    required this.accent,
    required this.highlight,
  });

  /// Surface of cards, tiles and chat bubbles.
  final Color card;
  final Color border;

  /// Quotation blocks and icon discs.
  final Color quoteSurface;

  /// Book text.
  final Color ink;

  /// Brown (light) or light gold (dark) for titles and icons on [card].
  final Color accent;

  /// Paragraph being read aloud.
  final Color highlight;

  static const light = BustanColors(
    card: Colors.white,
    border: AppTheme.goldSoft,
    quoteSurface: AppTheme.parchmentDeep,
    ink: AppTheme.ink,
    accent: AppTheme.brown,
    highlight: AppTheme.goldSoft,
  );

  static const dark = BustanColors(
    card: Color(0xFF2A211A),
    border: Color(0x59D9B77A),
    quoteSurface: Color(0xFF3A2E24),
    ink: Color(0xFFF0E6D4),
    accent: Color(0xFFD9B77A),
    highlight: Color(0x66D9B77A),
  );

  static BustanColors of(BuildContext context) =>
      Theme.of(context).extension<BustanColors>() ?? light;

  @override
  BustanColors copyWith({
    Color? card,
    Color? border,
    Color? quoteSurface,
    Color? ink,
    Color? accent,
    Color? highlight,
  }) =>
      BustanColors(
        card: card ?? this.card,
        border: border ?? this.border,
        quoteSurface: quoteSurface ?? this.quoteSurface,
        ink: ink ?? this.ink,
        accent: accent ?? this.accent,
        highlight: highlight ?? this.highlight,
      );

  @override
  BustanColors lerp(ThemeExtension<BustanColors>? other, double t) {
    if (other is! BustanColors) return this;
    return BustanColors(
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      quoteSurface: Color.lerp(quoteSurface, other.quoteSurface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
    );
  }
}

/// Arabic-first theme: warm parchment surfaces, deep monastic brown and
/// muted gold. UI font Tajawal; book text uses [bookFontFamily] (Amiri).
/// Light and dark variants; colors that are not part of Material's
/// [ColorScheme] live in the [BustanColors] theme extension.
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

  static const darkSurface = Color(0xFF1B1511);

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
    return _build(scheme, BustanColors.light);
  }

  static ThemeData dark() {
    const colors = BustanColors.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: brown,
      brightness: Brightness.dark,
    ).copyWith(
      primary: colors.accent,
      onPrimary: ink,
      secondary: gold,
      surface: darkSurface,
      onSurface: colors.ink,
      surfaceContainerHighest: colors.quoteSurface,
      tertiaryContainer: const Color(0xFF4A3A1C),
      onTertiaryContainer: const Color(0xFFF6E7C1),
      tertiary: colors.accent,
      outline: const Color(0xFF9C8A72),
      outlineVariant: const Color(0xFF4F4235),
    );
    return _build(scheme, colors);
  }

  static ThemeData _build(ColorScheme scheme, BustanColors colors) {
    final surface = scheme.surface;
    final ink = scheme.onSurface;
    final accent = scheme.primary;
    final isLight = scheme.brightness == Brightness.light;
    final softBorder = colors.border;
    final midBorder = isLight ? goldMid : const Color(0x80D9B77A);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [colors],
    );
    final text = base.textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: ink,
      displayColor: ink,
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
    return base.copyWith(
      scaffoldBackgroundColor: surface,
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
        backgroundColor: surface,
        foregroundColor: accent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
      cardTheme: CardTheme(
        color: colors.card,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: shape.copyWith(
          side: BorderSide(color: softBorder),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: accent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: midBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: midBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? accent : colors.quoteSurface,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: isLight ? Colors.white : ink,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: softBorder),
    );
  }
}
