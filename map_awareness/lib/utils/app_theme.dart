import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const FlexScheme _scheme = FlexScheme.blue;

  static ThemeData get lightTheme {
    final baseTheme = FlexThemeData.light(
      scheme: _scheme,
      useMaterial3: true,
      useMaterial3ErrorColors: true,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        defaultRadius: 16.0,
        elevatedButtonSchemeColor: SchemeColor.primary,
        elevatedButtonSecondarySchemeColor: SchemeColor.secondary,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 16.0,
        inputDecoratorUnfocusedHasBorder: true,
        fabUseShape: true,
        fabRadius: 16.0,
        chipRadius: 12.0,
        cardElevation: 0,
        cardRadius: 16.0,
        popupMenuRadius: 12.0,
        dialogRadius: 20.0,
        timePickerElementRadius: 16.0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      fontFamily: GoogleFonts.outfit().fontFamily,
    );
    
    return baseTheme.copyWith(
      expansionTileTheme: const ExpansionTileThemeData(),
    );
  }
}
