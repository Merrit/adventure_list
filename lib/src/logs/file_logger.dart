import 'dart:io';

import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;

import '../settings/settings.dart';

/// Log debug messages to a temp file.
class FileLogger {
  final File _logFile;

  /// Private constructor; should be created with [initialize].
  FileLogger._(this._logFile);

  static Future<FileLogger> initialize() async {
    final tempDir = await getTemporaryDirectory();
    final logFile = File(
      '${tempDir.path}${Platform.pathSeparator}adventure_list.log',
    );

    if (await logFile.exists()) {
      await logFile.delete();
    }
    await logFile.create();

    return FileLogger._(logFile);
  }

  Future<void> write(String msg) async {
    if (!settingsCubit.state.logToFile) return;

    await _logFile.writeAsString(
      msg,
      mode: FileMode.append,
      flush: true,
    );
  }
}
