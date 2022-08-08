import 'dart:io';

/// `FileOutput` import needed due to bug in package.
/// https://github.com/leisim/logger/issues/94
// ignore: implementation_imports
import 'package:logger/src/outputs/file_output.dart';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

late final Logger logger;

Future<void> initializeLogger() async {
  final dataDir = await getApplicationSupportDirectory();
  final logFile = File('${dataDir.path}${Platform.pathSeparator}log.txt');
  if (await logFile.exists()) await logFile.delete();
  await logFile.create();

  logger = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      colors: stdout.supportsAnsiEscapes,
      lineLength: (stdout.hasTerminal) ? stdout.terminalColumns : 120,
    ),
    output: MultiOutput([
      ConsoleOutput(),
      FileOutput(file: logFile),
    ]),
  );
}
