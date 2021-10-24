import 'package:flutter/material.dart';

abstract class BorderRadii {
  static BorderRadius gentlyRounded = BorderRadius.circular(10);
}

abstract class CustomColors {
  static const Color accentColor = Colors.lightBlueAccent;
  static Color fadedColor = Colors.grey.shade600;
  static const Color warningColor = Colors.red;
}

abstract class Spacers {
  static const horizontalSmall = SizedBox(width: 20);
  static const verticalXtraSmall = SizedBox(height: 10);
  static const verticalSmall = SizedBox(height: 20);
  static const verticalMedium = SizedBox(height: 30);
}

class TextStyles {
  static const TextStyle base = TextStyle();
  static TextStyle body1 = base.copyWith(fontSize: 15);
  static TextStyle link1 = body1.copyWith(color: Colors.lightBlueAccent);
  static TextStyle headline1 = base.copyWith(fontSize: 20);
  static TextStyle headline2 = base.copyWith(fontSize: 18);
}
