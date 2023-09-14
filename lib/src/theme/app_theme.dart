import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kFallbackFontFamilies = [
  /// Fallback to Noto Color Emoji is needed to render emojis in color.
  ///
  /// See:
  /// https://github.com/flutter/flutter/issues/119536
  'Noto Color Emoji',
];

/// The app's branded color.
const appColor = Color.fromRGBO(0, 179, 255, 1);

/// Dark app theme.
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorSchemeSeed: appColor,
  dialogTheme: const DialogTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  ),
  fontFamily: GoogleFonts.notoSans().fontFamily,
  fontFamilyFallback: _kFallbackFontFamilies,
);

/// Light app theme.
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorSchemeSeed: appColor,
  dialogTheme: const DialogTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  ),
  fontFamily: GoogleFonts.notoSans().fontFamily,
  fontFamilyFallback: _kFallbackFontFamilies,
);
