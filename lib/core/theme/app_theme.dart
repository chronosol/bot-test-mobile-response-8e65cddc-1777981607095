import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_config.dart';

class AppTheme {
  AppTheme._();

  // ── Brand colours (parsed from AppConfig) ─────────────────────────────────
  static Color get primary => _hexToColor(AppConfig.primaryColorHex);
  static Color get accent  => _hexToColor(AppConfig.accentColorHex);

  static Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color _dark        = Color(0xFF0D0D14);
  static const Color _darkSurface = Color(0xFF16161F);
  static const Color _darkCard    = Color(0xFF1E1E2A);
  static const Color _darkBorder  = Color(0xFF2A2A3C);
  static const Color _onDark      = Color(0xFFF0F0FF);
  static const Color _onDarkMuted = Color(0xFF8888AA);

  static const Color _light        = Color(0xFFF5F5FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightCard    = Color(0xFFFFFFFF);
  static const Color _lightBorder  = Color(0xFFE8E8F0);
  static const Color _onLight      = Color(0xFF0D0D14);
  static const Color _onLightMuted = Color(0xFF8888AA);

  // ── Bot bubble colour ──────────────────────────────────────────────────────
  static Color botBubbleDark(BuildContext ctx)  => const Color(0xFF1E1E2A);
  static Color botBubbleLight(BuildContext ctx) => const Color(0xFFFFFFFF);

  // ── Dark theme ────────────────────────────────────────────────────────────
  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor:   primary,
      brightness:  Brightness.dark,
    ).copyWith(
      primary:              primary,
      secondary:            accent,
      surface:              _darkSurface,
      onSurface:            _onDark,
      surfaceContainerHighest: _darkCard,
      outline:              _darkBorder,
      onSurfaceVariant:     _onDarkMuted,
    );

    return ThemeData(
      useMaterial3:     true,
      brightness:       Brightness.dark,
      colorScheme:      cs,
      scaffoldBackgroundColor: _dark,
      fontFamily:       'Satoshi',

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation:       0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily:  'Satoshi',
          fontSize:    17,
          fontWeight:  FontWeight.w700,
          color:       _onDark,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color:        _darkCard,
        elevation:    0,
        shape:        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side:         const BorderSide(color: _darkBorder, width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   _darkCard,
        border:      OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide:   const BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide:   const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide:   BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        hintStyle:   const TextStyle(color: _onDarkMuted, fontSize: 15),
      ),

      textTheme: _textTheme(_onDark, _onDarkMuted),
    );
  }

  // ── Light theme ───────────────────────────────────────────────────────────
  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor:  primary,
      brightness: Brightness.light,
    ).copyWith(
      primary:              primary,
      secondary:            accent,
      surface:              _lightSurface,
      onSurface:            _onLight,
      surfaceContainerHighest: _lightCard,
      outline:              _lightBorder,
      onSurfaceVariant:     _onLightMuted,
    );

    return ThemeData(
      useMaterial3:     true,
      brightness:       Brightness.light,
      colorScheme:      cs,
      scaffoldBackgroundColor: _light,
      fontFamily:       'Satoshi',

      appBarTheme: AppBarTheme(
        backgroundColor: _lightSurface,
        elevation:       0,
        scrolledUnderElevation: 0.5,
        shadowColor:    _lightBorder,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: const TextStyle(
          fontFamily:  'Satoshi',
          fontSize:    17,
          fontWeight:  FontWeight.w700,
          color:       _onLight,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color:     _lightCard,
        elevation: 0,
        shape:     RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side:         const BorderSide(color: _lightBorder, width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: _lightCard,
        border:    OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide:   const BorderSide(color: _lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide:   const BorderSide(color: _lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide:   BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        hintStyle: const TextStyle(color: _onLightMuted, fontSize: 15),
      ),

      textTheme: _textTheme(_onLight, _onLightMuted),
    );
  }

  static TextTheme _textTheme(Color primary, Color muted) => TextTheme(
    displayLarge:  TextStyle(fontFamily: 'Satoshi', fontSize: 48, fontWeight: FontWeight.w900, color: primary, letterSpacing: -2),
    displayMedium: TextStyle(fontFamily: 'Satoshi', fontSize: 36, fontWeight: FontWeight.w900, color: primary, letterSpacing: -1.5),
    displaySmall:  TextStyle(fontFamily: 'Satoshi', fontSize: 28, fontWeight: FontWeight.w700, color: primary, letterSpacing: -1),
    headlineLarge: TextStyle(fontFamily: 'Satoshi', fontSize: 24, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.8),
    headlineMedium:TextStyle(fontFamily: 'Satoshi', fontSize: 20, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.5),
    titleLarge:    TextStyle(fontFamily: 'Satoshi', fontSize: 17, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.3),
    titleMedium:   TextStyle(fontFamily: 'Satoshi', fontSize: 15, fontWeight: FontWeight.w500, color: primary),
    titleSmall:    TextStyle(fontFamily: 'Satoshi', fontSize: 13, fontWeight: FontWeight.w500, color: muted),
    bodyLarge:     TextStyle(fontFamily: 'Satoshi', fontSize: 15, fontWeight: FontWeight.w400, color: primary, height: 1.5),
    bodyMedium:    TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w400, color: primary, height: 1.5),
    bodySmall:     TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: FontWeight.w400, color: muted),
    labelLarge:    TextStyle(fontFamily: 'Satoshi', fontSize: 15, fontWeight: FontWeight.w700, color: primary, letterSpacing: 0.2),
    labelMedium:   TextStyle(fontFamily: 'Satoshi', fontSize: 13, fontWeight: FontWeight.w500, color: primary),
    labelSmall:    TextStyle(fontFamily: 'Satoshi', fontSize: 11, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.5),
  );
}
