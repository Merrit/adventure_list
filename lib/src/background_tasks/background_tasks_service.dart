import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../core/helpers/helpers.dart';
import '../logs/logging_manager.dart';

/// Background task name for refreshing data.
const _refreshDataBackgroundTask = 'refreshDataBackgroundTask';

/// Initializes the service to listen for background tasks to be executed.
///
/// Only available on Android.
Future<void> initializeBackgroundTasks() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;

  log.d('Initializing background tasks service');

  await Workmanager().initialize(
    _callbackDispatcher,
    isInDebugMode: kDebugMode,
  );

  await Workmanager().registerPeriodicTask(
    _refreshDataBackgroundTask,
    _refreshDataBackgroundTask,
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(minutes: 15),
  );
}

/// Acts as the entry point for tasks from the Workmanager plugin.
///
/// For example, when a task is scheduled to run every 15 minutes, this function
/// will be called by the system every 15 minutes.
@pragma('vm:entry-point')
void _callbackDispatcher() {
  /// Workmanager().executeTask(...) supports 3 possible return values:
  ///
  /// - Future.value(true): The task is successful.
  /// - Future.value(false): The task did not complete successfully and needs to
  ///   be retried. On Android, the retry is done automatically. On iOS (when
  ///   using BGTaskScheduler), the retry needs to be scheduled manually.
  /// - Future.error(...): The task failed.
  ///
  /// On Android, the BackoffPolicy will configure how WorkManager is going to
  /// retry the task.
  ///
  /// All dependencies must be initialized inside the callback, as it is
  /// executed in a background isolate and does not have access to any services
  /// initialized in the main isolate.
  ///
  /// For example, initializing the logger before using it.
  Workmanager().executeTask((taskName, inputData) async {
    await LoggingManager.initialize(verbose: kDebugMode);
    initializePlatformErrorHandler();
    log.d('Background task called: $taskName');

    switch (taskName) {
      case _refreshDataBackgroundTask:
        log.d('Refreshing data in background');
        return _refreshDataFromBackgroundIsolate();
      default:
        log.w('Unknown background task: $taskName');
        return Future.error('Unknown background task: $taskName');
    }
  });
}

/// Refreshes data from the background isolate.
///
/// This function is called from the background isolate, so it does not have
/// access to any services initialized in the main isolate.
Future<bool> _refreshDataFromBackgroundIsolate() async {
  // TODO: Implement this function.
  return Future.value(true);
}
