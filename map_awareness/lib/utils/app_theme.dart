import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized design system definition for the application.
class AppTheme {
  AppTheme._();

  // Branding colors.
  static const Color primary = Color(0xFF1E88E5);
  static const Color accent = Color(0xFF00BCD4);
  static const Color error = Color(0xFFFF5252);

  // Spacing & Corner Radius.
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double spacingMd = 16.0;

  // Animation durations.
  static const Duration animNormal = Duration(milliseconds: 300);

  /// Shadow for cards, adapting to brightness.
  static List<BoxShadow> cardShadow(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) return [];
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// Generates the light theme data.
  static ThemeData get lightTheme => FlexThemeData.light(
        scheme: FlexScheme.blue,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          useMaterial3Typography: true,
          useM2StyleDividerInM3: true,
          defaultRadius: radiusMd,
          inputDecoratorRadius: radiusMd,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
      ).copyWith(
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      );

  /// Generates the dark theme data.
  static ThemeData get darkTheme => FlexThemeData.dark(
        scheme: FlexScheme.blue,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 15,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useMaterial3Typography: true,
          useM2StyleDividerInM3: true,
          defaultRadius: radiusMd,
          inputDecoratorRadius: radiusMd,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
      ).copyWith(
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      );

  /// Maps theme mode index to ThemeMode enum (0=light, 1=dark, 2=system).
  static ThemeMode themeModeFromIndex(int index) {
    switch (index) {
      case 1: return ThemeMode.dark;
      case 2: return ThemeMode.system;
      default: return ThemeMode.light;
    }
  }
}



