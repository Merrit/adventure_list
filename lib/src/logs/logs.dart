import 'dart:io';

import 'package:helpers/helpers.dart';

/// `FileOutput` import needed due to bug in package.
/// https://github.com/leisim/logger/issues/94
// ignore: implementation_imports
import 'package:logger/src/outputs/file_output.dart';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../storage/storage_service.dart';

late final Logger logger;

Future<void> initializeLogger(
  StorageService storageService, {
  bool? logToFile,
}) async {
  if (testing) {
    logger = Logger();
    return;
  }

  logToFile ??= await storageService.getValue('logToFile');

  final dataDir = await getApplicationSupportDirectory();
  final logFile = File('${dataDir.path}${Platform.pathSeparator}log.txt');
  if (await logFile.exists()) await logFile.delete();
  await logFile.create();

  final List<LogOutput> outputs = [
    ConsoleOutput(),
  ];

  if (logToFile == true) outputs.add(FileOutput(file: logFile));

  logger = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      colors: stdout.supportsAnsiEscapes,
      lineLength: (stdout.hasTerminal) ? stdout.terminalColumns : 120,
    ),
    output: MultiOutput(outputs),
  );
}
