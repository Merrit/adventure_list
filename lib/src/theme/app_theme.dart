import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app's branded color.
const appColor = Color.fromRGBO(0, 179, 255, 1);

/// Dark app theme.
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorSchemeSeed: appColor,
  fontFamily: GoogleFonts.notoSans().fontFamily,
);

/// Light app theme.
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorSchemeSeed: appColor,
  fontFamily: GoogleFonts.notoSans().fontFamily,
);
