import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData _flexDarkTheme = FlexThemeData.dark(
  scheme: FlexScheme.blue,
  surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
  blendLevel: 40,
  appBarStyle: FlexAppBarStyle.background,
  appBarOpacity: 0.90,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 30,
    dialogRadius: 14.0,
    timePickerDialogRadius: 14.0,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  // useMaterial3: true,
  fontFamily: GoogleFonts.notoSans().fontFamily,
);

final ThemeData _flexLightTheme = FlexThemeData.light(
  scheme: FlexScheme.blue,
  surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
  blendLevel: 20,
  appBarOpacity: 0.95,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 20,
    blendOnColors: false,
    dialogRadius: 14.0,
    timePickerDialogRadius: 14.0,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  // useMaterial3: true,
  fontFamily: GoogleFonts.notoSans().fontFamily,
);

final ThemeData darkTheme = _flexDarkTheme.copyWith(
  // Impossible to read button by default.
  snackBarTheme: _flexDarkTheme.snackBarTheme.copyWith(
    actionTextColor: _flexDarkTheme.colorScheme.onPrimary,
  ),
);

final ThemeData lightTheme = _flexLightTheme.copyWith(
  // Impossible to read button by default.
  snackBarTheme: _flexLightTheme.snackBarTheme.copyWith(
    actionTextColor: _flexLightTheme.colorScheme.onPrimary,
  ),
);
