import 'package:flutter/foundation.dart';

import '../../logs/logging_manager.dart';

/// Handle platform errors not caught by Flutter.
///
/// This is useful for errors that happen outside of the Flutter context, such as
/// errors in the platform, or plugins.
void initializePlatformErrorHandler() {
  PlatformDispatcher.instance.onError = (error, stack) {
    log.e('Uncaught platform error', error: error, stackTrace: stack);
    return true;
  };
}
