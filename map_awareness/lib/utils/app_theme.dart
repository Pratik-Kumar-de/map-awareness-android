import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium app theme with modern design tokens using FlexColorScheme
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1E88E5);
  static const Color accent = Color(0xFF00BCD4);
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF448AFF);
  static const Color civil = Color(0xFF7C4DFF);

  // Severity Colors
  static const Color severityMinor = Color(0xFF42A5F5);
  static const Color severityModerate = Color(0xFFFFA000);
  static const Color severitySevere = Color(0xFFFF6D00);
  static const Color severityExtreme = Color(0xFFE53935);
  
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  
  static const Color surfaceContainer = Color(0xFFF1F5F9);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0);
  static const Color accentLight = Color(0xFF4DD0E1);
  static const Color primaryLight = Color(0xFF42A5F5);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
  ];

  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;

  static const double spacing16 = 16.0;
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 400);

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(color: primary.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
  ];

  static Color get surface => Colors.white;

  static ThemeData get lightTheme => FlexThemeData.light(
        colors: const FlexSchemeColor(
          primary: primary,
          primaryContainer: Color(0xFFD1E4FF),
          secondary: accent,
          secondaryContainer: Color(0xFFE0F7FA),
          tertiary: Color(0xFF7C4DFF),
          tertiaryContainer: Color(0xFFEDE7F6),
          appBarColor: Color(0xFFE0F7FA),
          error: error,
        ),
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
          useMaterial3Typography: true,
          useM2StyleDividerInM3: true,
          defaultRadius: radiusMd,
          thinBorderWidth: 1.0,
          filledButtonRadius: radiusSm,
          elevatedButtonRadius: radiusSm,
          outlinedButtonRadius: radiusSm,
          inputDecoratorIsFilled: true,
          inputDecoratorRadius: radiusMd,
          inputDecoratorUnfocusedBorderIsColored: false,
          navigationBarLabelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          navigationBarIndicatorSchemeColor: SchemeColor.primary,
          navigationBarIndicatorOpacity: 0.12,
          navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
          navigationBarSelectedIconSchemeColor: SchemeColor.primary,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
      ).copyWith(
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      );
}


