import 'package:flutter/widgets.dart';

extension MediaQueryHelpers on MediaQueryData {
  /// Matches the Large breakpoint from the flutter_adaptive_scaffold package.
  bool get isSmallScreen => size.width < 840;
}
