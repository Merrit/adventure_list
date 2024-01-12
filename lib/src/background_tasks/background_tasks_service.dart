import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../authentication/authentication.dart';
import '../core/helpers/helpers.dart';
import '../home_widget/home_widget.dart';
import '../logs/logging_manager.dart';
import '../storage/storage.dart';
import '../tasks/tasks.dart';

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
    // Set to true to debug background tasks.
    // Defaulting to false because it sends constant notifications to the
    // device that the app is running in debug mode.
    isInDebugMode: false,
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
  final storageRepository = await StorageRepository.initialize(Hive);
  final googleAuth = GoogleAuth(storageRepository);

  final client = await googleAuth.getAuthClient();
  if (client == null) {
    log.w('Could not get an authenticated client');
    return false;
  }

  final calendarApi = CalendarApi(client);
  final tasksRepository = GoogleCalendar(calendarApi);
  final backgroundTasksService = BackgroundTasksService(
    HomeWidgetManager(),
    storageRepository,
    tasksRepository,
  );

  final bool success = await backgroundTasksService.refreshData();

  if (success) {
    log.d('Successfully refreshed data in the background.');
  }

  return success;
}

/// Service to perform background tasks.
class BackgroundTasksService {
  final HomeWidgetManager _homeWidgetManager;
  final StorageRepository _storageRepository;
  final TasksRepository _tasksRepository;

  const BackgroundTasksService(
    this._homeWidgetManager,
    this._storageRepository,
    this._tasksRepository,
  );

  /// Fetches the latest data from the repository then updates the local storage
  /// and the Android home screen widget.
  Future<bool> refreshData() async {
    // Get the latest data from the repository.
    final List<TaskList>? remoteTaskLists = await _tasksRepository.getAll();
    if (remoteTaskLists == null) {
      log.w('Could not get data from the repository');
      return false;
    } else if (remoteTaskLists.isEmpty) {
      log.d('Remote data is empty');
      return false;
    }

    // Update the local storage.
    await _storageRepository.save(
      key: 'taskListsJson',
      value: remoteTaskLists.map((e) => jsonEncode(e.toJson())).toList(),
      storageArea: 'cache',
    );

    // Update the widget.
    await _updateHomeWidget(remoteTaskLists);

    return true;
  }

  /// Update the Android home screen widget with the latest data.
  Future<void> _updateHomeWidget(List<TaskList> remoteTaskLists) async {
    // The id of the list that the home widget displays.
    final String? listId = await _storageRepository.get(
      'homeWidgetSelectedListId',
    );
    if (listId == null) {
      log.w('Could not get the id of the list that the home widget displays, '
          'or the widget is not configured.');
      return;
    }

    // The list that the home widget displays.
    final TaskList? taskList = remoteTaskLists.firstWhereOrNull(
      (e) => e.id == listId,
    );
    if (taskList == null) {
      log.w('Could not find the list that the home widget displays');
      return;
    }

    // Update the widget.
    await _homeWidgetManager.updateHomeWidget(
      listId,
      jsonEncode(taskList.toJson()),
    );
  }
}
