import 'package:flutter/widgets.dart';

extension MediaQueryHelpers on MediaQueryData {
  bool get isSmallScreen => size.width < 600;
}
