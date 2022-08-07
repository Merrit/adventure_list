import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import 'file_logger.dart';

/// Print log messages.
Future<void> initializeLogger() async {
  final fileLogger = await FileLogger.initialize();
  Logger.root.level = Level.ALL;

  Logger.root.onRecord.listen((record) async {
    final String time = DateFormat('h:mm:ss a').format(record.time);

    var msg = '${record.level.name}: $time: '
        '${record.loggerName}: ${record.message}';

    if (record.error != null) msg += '\nError: ${record.error}';

    debugPrint(msg);
    await fileLogger.write(msg);
  });
}
