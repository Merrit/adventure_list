import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Get the application support directory.
///
/// Defaults to `~/.local/share/<app_name>/` on Linux.
///
/// For dev builds, this will be in a `dev` subdirectory.
/// For tests this will be in a `test` subdirectory.
Future<Directory> getSupportDirectory() async {
  final Directory dir = await getApplicationSupportDirectory();
  final separator = Platform.pathSeparator;

  if (kDebugMode) {
    return Directory('${dir.path}${separator}dev');
  }

  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return Directory('${dir.path}${separator}test');
  }

  return dir;
}
