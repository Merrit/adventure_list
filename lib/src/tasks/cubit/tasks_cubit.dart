import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:uuid/uuid.dart';

import '../../authentication/authentication.dart';
import '../../home_widget/home_widget_manager.dart';
import '../../logs/logs.dart';
import '../../notifications/notifications.dart';
import '../../settings/settings.dart';
import '../../storage/storage_repository.dart';
import '../tasks.dart';

part 'tasks_state.dart';
part 'tasks_cubit.freezed.dart';
part 'tasks_cubit.g.dart';

/// Global instance of the [TasksCubit].
///
/// Allows access without a [BuildContext].
late TasksCubit tasksCubit;

/// Cubit that manages the state of the tasks.
class TasksCubit extends Cubit<TasksState> {
  /// Uuid generator.
  ///
  /// Passed in as a dependency to allow for mocking in unit tests.
  final Uuid _uuid;

  TasksCubit(
    AuthenticationCubit authCubit, {
    TasksRepository? tasksRepository,
    Uuid? uuid,
  })  : _uuid = uuid ?? const Uuid(),
        super(TasksState.initial()) {
    tasksCubit = this;

    _getCachedData();

    // If already signed in, initialize the tasks.
    if (authCubit.state.signedIn) {
      _getTasksRepo(
        credentials: authCubit.state.accessCredentials!,
        tasksRepository: tasksRepository,
      );
    }

    authCubit.stream.listen((AuthenticationState authState) async {
      // If sign in happens after cubit is created, initialize the tasks.
      if (authState.signedIn) {
        _getTasksRepo(
          credentials: authCubit.state.accessCredentials!,
          tasksRepository: tasksRepository,
        );
      }
    });
  }

  /// Loads cached data from local storage.
  ///
  /// This is used to show the user something while the tasks are being fetched.
  Future<void> _getCachedData() async {
    final List<String>? taskListsJson = await StorageRepository.instance.get(
      'taskListsJson',
      storageArea: 'cache',
    );

    if (taskListsJson == null) {
      emit(state.copyWith(loading: false));
      return;
    }

    final List<TaskList> taskLists = taskListsJson //
        .map((e) => TaskList.fromJson(jsonDecode(e)))
        .toList();

    final String? activeListId = await StorageRepository.instance.get(
      'activeList',
    );

    emit(state.copyWith(
      activeList: taskLists.singleWhereOrNull((e) => e.id == activeListId),
      loading: false,
      taskLists: taskLists.sorted(),
    ));
  }

  /// Initializes the tasks repository.
  Future<void> _getTasksRepo({
    required AccessCredentials credentials,
    TasksRepository? tasksRepository,
  }) async {
    if (tasksRepository == null) {
      /// If [tasksRepository] is non-null it was passed in as a mock.
      final client = await _getAuthClient();
      final calendarApi = CalendarApi(client!);
      tasksRepository ??= GoogleCalendar(calendarApi);
    }

    initialize(tasksRepository);
  }

  /// Returns an `AuthClient` that can be used to make authenticated requests.
  Future<AuthClient?> _getAuthClient() async {
    final credentials = await StorageRepository.instance.get(
      'accessCredentials',
    );
    if (credentials == null) return null;

    final accessCredentials = AccessCredentials.fromJson(
      json.decode(credentials),
    );

    AuthClient? client;
    // `google_sign_in` can't get us a refresh token, so.
    if (accessCredentials.refreshToken != null) {
      client = autoRefreshingClient(
        GoogleAuthIds.clientId,
        accessCredentials,
        Client(),
      );
    } else {
      client = await GoogleAuth.refreshAuthClient();
    }

    return client;
  }

  late TasksRepository _tasksRepository;

  /// Initializes the [TasksCubit].
  Future<void> initialize(TasksRepository tasksRepository) async {
    _tasksRepository = tasksRepository;

    // If we have cached data we don't show a loading indicator.
    emit(state.copyWith(loading: state.taskLists.isEmpty));

    List<TaskList>? taskLists;
    try {
      taskLists = await _tasksRepository.getAll();
    } catch (e) {
      log.w('Exception while attempting to fetch tasks: $e');
      // Do we want to sign out??
      // await authCubit.signOut();
      return;
    }

    assert(taskLists != null);

    final String? activeListId = await StorageRepository.instance.get(
      'activeList',
    );

    emit(state.copyWith(
      activeList: taskLists?.singleWhereOrNull((e) => e.id == activeListId),
      loading: false,
      taskLists: taskLists!.sorted(),
    ));

    await _scheduleNotifications(taskLists);
    _listenForNotificationResponse();
  }

  /// Schedules notifications for all tasks that have a due date and are not
  /// completed.
  Future<void> _scheduleNotifications(List<TaskList> taskLists) async {
    for (final taskList in taskLists) {
      for (final task in taskList.items) {
        if (task.dueDate != null && !task.completed) {
          await NotificationsCubit.instance.scheduleNotification(task);
        }
      }
    }
  }

  /// Creates a new Todo list.
  ///
  /// The list is created in memory first, then synced with the repository.
  /// This is done so the process feels fast to the user.
  Future<void> createList(String title) async {
    final TaskList? previousActiveList = state.activeList;

    // Quickly create a list in memory for good UX.
    final newListTempId = _uuid.v4();
    TaskList newList = TaskList(
      id: newListTempId,
      index: state.taskLists.length,
      items: const [],
      title: title,
    );
    emit(state.copyWith(
      activeList: newList,
      taskLists: state.taskLists.addTaskList(newList),
    ));

    // Create list properly through repository to get id & etc.
    final newListFromRepo = await _tasksRepository.createList(newList);
    if (newListFromRepo == null) {
      // If the list wasn't created properly, revert the changes.
      emit(state.copyWith(
        activeList: previousActiveList,
        taskLists: state.taskLists.removeTaskList(newListTempId),
      ));
      return;
    }

    newList = newList.copyWith(id: newListFromRepo.id, synced: true);
    final List<TaskList> taskLists = state //
        .taskLists
        .removeTaskList(newListTempId)
        .addTaskList(newList);
    emit(state.copyWith(
      activeList: newList,
      taskLists: taskLists,
    ));
  }

  /// Deletes the active list.
  Future<void> deleteList() async {
    final TaskList? activeList = state.activeList;
    if (activeList == null) return;

    final updatedLists = state.taskLists.removeTaskList(activeList.id);
    emit(state.copyWith(
      activeList: null,
      activeTask: null,
      taskLists: updatedLists,
    ));
    await _tasksRepository.deleteList(id: activeList.id);
  }

  /// Called when the user is reordering the list of TaskLists.
  Future<void> reorderLists(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final List<TaskList> taskLists = state //
        .taskLists
        .reorderTaskLists(state.taskLists[oldIndex], newIndex);
    for (var i = 0; i < taskLists.length; i++) {
      taskLists[i] = taskLists[i].copyWith(synced: false);
    }
    // Emit the active list again because its index might have changed.
    final activeList = taskLists.singleWhereOrNull(
      (e) => e.id == state.activeList?.id,
    );
    emit(state.copyWith(
      taskLists: taskLists,
      activeList: activeList,
    ));
  }

  /// Sets the active list to the list with the provided [id].
  ///
  /// If the list with the provided [id] doesn't exist, the active list is set
  /// to null.
  ///
  /// The active list id is saved to storage so it can be retrieved on app
  /// restart.
  void setActiveList(String id) {
    final TaskList? taskList = state.taskLists.getTaskListById(id);
    emit(state.copyWith(
      activeList: taskList,
      activeTask: null,
    ));
    StorageRepository.instance.save(key: 'activeList', value: taskList?.id);
  }

  /// Updates the provided [TaskList].
  ///
  /// The list is updated in memory first, then synced with the repository to
  /// ensure the process feels fast to the user.
  ///
  /// If the list is the active list, it is also updated in memory.
  Future<void> updateList(TaskList list) async {
    final updatedLists = state.taskLists.updateTaskList(list);
    final TaskList? activeList = (list.id == state.activeList?.id) //
        ? list
        : null;
    emit(state.copyWith(
      activeList: activeList,
      taskLists: updatedLists,
    ));
    await _tasksRepository.updateList(list: list);
  }

  /// Creates a new [Task] in the active list.
  ///
  /// The task is created in memory first, then synced with the repository to
  /// ensure the process feels fast to the user.
  Future<Task?> createTask(Task newTask) async {
    assert(state.activeList != null);

    final TaskList activeList = state.activeList!;
    final List<TaskList> taskLists = state.taskLists;
    final tempId = _uuid.v4();
    final index = _calculateNewTaskIndex(newTask);
    newTask = newTask.copyWith(id: tempId, index: index);
    List<Task> updatedTasks = activeList.items.addTask(newTask);
    TaskList updatedTaskList = activeList.copyWith(items: updatedTasks);
    List<TaskList> updatedTaskLists = taskLists.updateTaskList(updatedTaskList);

    // Emit local cached task immediately.
    emit(state.copyWith(
      activeList: updatedTaskList,
      taskLists: updatedTaskLists,
    ));

    // Create task with repository to get final id.
    final newTaskFromRepo = await _tasksRepository.createTask(
      taskListId: state.activeList!.id,
      newTask: newTask,
    );

    // If creating the remote task failed, revert the changes.
    if (newTaskFromRepo == null) {
      emit(state.copyWith(
        activeList: activeList,
        taskLists: taskLists,
      ));
      return null;
    }

    updatedTasks = updatedTaskList.items //
        .removeTask(newTask)
        .addTask(newTaskFromRepo);
    updatedTaskList = updatedTaskList.copyWith(items: updatedTasks);
    updatedTaskLists = updatedTaskLists.updateTaskList(updatedTaskList);

    emit(state.copyWith(
      activeList: updatedTaskList,
      taskLists: updatedTaskLists,
    ));

    return newTaskFromRepo;
  }

  /// Calculate the index of a new task.
  ///
  /// If the task is a subtask, the index is the number of subtasks of the
  /// parent task.
  ///
  /// If the task is not a subtask, the index is the number of tasks without
  /// a parent.
  int _calculateNewTaskIndex(Task newTask) {
    final bool isSubTask = newTask.parent != null;
    final Task? parentTask = state.activeList!.items
        .singleWhereOrNull((element) => element.id == newTask.parent);

    int index;
    if (isSubTask) {
      index = state.activeList!.items
          .where((element) => element.parent == parentTask!.id)
          .length;
    } else {
      index = state.activeList!.items
          .where((element) => element.parent == null)
          .length;
    }
    return index;
  }

  /// Called when the user is reordering Tasks.
  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final List<Task> items = state.activeList!.items.copy()
      ..removeAt(oldIndex)
      ..insert(newIndex, state.activeList!.items[oldIndex]);
    for (var i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(index: i, synced: false);
    }
    final TaskList updatedList = state.activeList!.copyWith(items: items);
    final updatedLists = state.taskLists.copy()
      ..remove(state.activeList)
      ..add(updatedList);
    emit(state.copyWith(
      activeList: updatedList,
      taskLists: updatedLists.sorted(),
    ));
    // sync tasks that have changed
    for (var i = 0; i < items.length; i++) {
      if (items[i].index != i) {
        await _tasksRepository.updateTask(
          taskListId: state.activeList!.id,
          updatedTask: items[i].copyWith(index: i),
        );
      }
    }
  }

  /// Updates the provided [Task].
  Future<Task> updateTask(Task task) async {
    final taskList = state.taskLists.getTaskListById(task.taskListId);
    if (taskList == null) throw Exception('Task list not found');

    // If the task is unchanged, don't do anything.
    if (taskList.items.contains(task)) return task;

    final bool isActiveTaskList = (state.activeList?.id == taskList.id);
    final bool isActiveTask = (state.activeTask?.id == task.id);
    final int taskIndex = taskList.items.indexWhere((t) => t.id == task.id);

    // Update local state immediately.
    final items = List<Task>.from(taskList.items)
      ..removeAt(taskIndex)
      ..insert(taskIndex, task);
    final taskLists = state.taskLists;
    final int taskListIndex = taskLists.indexWhere(
      (element) => element.id == taskList.id,
    );
    final TaskList updatedTaskList = taskList.copyWith(items: items);
    final List<TaskList> updatedAllTaskLists = taskLists.copy()
      ..[taskListIndex] = updatedTaskList;

    emit(state.copyWith(
      activeList: isActiveTaskList ? updatedTaskList : state.activeList,
      activeTask: isActiveTask ? task : state.activeTask,
      taskLists: updatedAllTaskLists,
    ));

    // Update with repository.
    final updatedTask = await _tasksRepository.updateTask(
      taskListId: task.taskListId,
      updatedTask: task,
    );

    // If the update failed, revert the changes.
    if (updatedTask == null) {
      emit(state.copyWith(
        activeList: isActiveTaskList ? taskList : state.activeList,
        activeTask: isActiveTask ? task : state.activeTask,
        taskLists: taskLists,
      ));
      return task;
    }

    // Update local state with updated task.
    final updatedItems = List<Task>.from(taskList.items)
      ..removeAt(taskIndex)
      ..insert(taskIndex, updatedTask);

    final updatedTaskListWithUpdatedTask = taskList.copyWith(
      items: updatedItems,
    );

    final updatedAllTaskListsWithUpdatedTask = taskLists.copy()
      ..[taskListIndex] = updatedTaskListWithUpdatedTask;

    emit(state.copyWith(
      activeList:
          isActiveTaskList ? updatedTaskListWithUpdatedTask : state.activeList,
      activeTask: isActiveTask ? updatedTask : state.activeTask,
      taskLists: updatedAllTaskListsWithUpdatedTask,
    ));

    return updatedTask;
  }

  /// Sets the [Task] with the provided [id] as the active task.
  ///
  /// If the [id] is null or no task with that [id] exists, the active task is
  /// set to null.
  ///
  /// If the task belongs to a different list than the active list, the active
  /// list is set to the list that contains the task.
  void setActiveTask(String? id) {
    final Task? task = state.taskLists
        .expand((element) => element.items)
        .firstWhereOrNull((element) => element.id == id);
    if (task == null) {
      emit(state.copyWith(activeTask: null));
      return;
    }

    final TaskList? taskList = state.taskLists
        .firstWhereOrNull((element) => element.items.contains(task));
    if (taskList == null) {
      emit(state.copyWith(activeTask: null));
      return;
    }

    if (taskList.id != state.activeList?.id) {
      setActiveList(taskList.id);
    }

    emit(state.copyWith(activeTask: task));
  }

  /// Holds the `activeList` as it was before the tasks were cleared until the
  /// timer expires and they are deleted, or the user cancels the clear
  /// operation and this list is restored.
  ///
  /// If the user takes any other actions aside from canceling the clear
  /// operation, this list is discarded.
  TaskList? _activeListBeforeClear;

  /// Timer giving the user time to cancel the clear operation.
  Timer? _clearTimer;

  /// Clears all completed tasks from the active list.
  ///
  /// If [parentId] is provided, only that parent task and its sub-tasks will be
  /// cleared.
  ///
  /// A task is marked "completed" when it is checked, but this does not remove
  /// it from the list, rather it is displayed differently; for example crossed
  /// out, hidden in a dropdown, etc. By "clearing" we are actually deleting the
  /// task.
  ///
  /// The user can cancel the clear operation by calling
  /// [undoClearCompletedTasks].
  Future<void> clearCompletedTasks({String? parentId}) async {
    final activeList = state.activeList;
    if (activeList == null) return;

    final List<Task> tasksToBeCleared = [];

    if (parentId != null) {
      final parentTask = activeList.items.getTaskById(parentId);
      tasksToBeCleared.addAll(activeList.items.subtasksOf(parentId));
      tasksToBeCleared.add(parentTask!);
    } else {
      tasksToBeCleared.addAll(activeList.items.completedTasks());
    }

    // If there are no tasks to be cleared, don't do anything.
    if (tasksToBeCleared.isEmpty) return;

    // Save state before clearing tasks so that it can be restored if the user
    // cancels the clear operation.
    _activeListBeforeClear = activeList;

    // Remove the tasks from the list.
    final List<Task> updatedTasks = activeList //
        .items
        .removeTasks(tasksToBeCleared);

    // Update the active list.
    final int index = state.taskLists.indexWhere(
      (element) => element.id == activeList.id,
    );
    final TaskList updatedTaskList = activeList.copyWith(items: updatedTasks);
    final List<TaskList> updatedAllTaskLists = state.taskLists.copy()
      ..[index] = updatedTaskList;

    emit(state.copyWith(
      activeList: updatedTaskList,
      awaitingClearTasksUndo: true,
      taskLists: updatedAllTaskLists,
    ));

    // Start the timer to clear the tasks.
    _clearTimer = Timer(const Duration(seconds: 10), () async {
      emit(state.copyWith(awaitingClearTasksUndo: false));

      for (var task in tasksToBeCleared) {
        await _tasksRepository.deleteTask(
          taskListId: activeList.id,
          taskId: task.id,
        );
      }

      _activeListBeforeClear = null;
      _clearTimer = null;
    });
  }

  /// Cancels the clear operation and restores the tasks that were cleared.
  void undoClearCompletedTasks() {
    if (_activeListBeforeClear == null) return;

    final activeListBeforeClear = _activeListBeforeClear!;
    final int index = state.taskLists.indexWhere(
      (element) => element.id == activeListBeforeClear.id,
    );
    final List<TaskList> updatedAllTaskLists = state.taskLists.copy()
      ..[index] = activeListBeforeClear;

    emit(state.copyWith(
      activeList: activeListBeforeClear,
      awaitingClearTasksUndo: false,
      taskLists: updatedAllTaskLists,
    ));

    _activeListBeforeClear = null;
    _clearTimer?.cancel();
    _clearTimer = null;
  }

  @override
  void onChange(Change<TasksState> change) {
    super.onChange(change);

    // If the user has taken an action while the clear timer is active, consider
    // the clear operation committed.
    if (change.currentState.awaitingClearTasksUndo &&
        change.nextState.awaitingClearTasksUndo) {
      _activeListBeforeClear = null;
      emit(state.copyWith(awaitingClearTasksUndo: false));
    }

    if (change.currentState != change.nextState) {
      _cacheData(change.nextState);
    }

    if (Platform.isAndroid) _updateAndroidWidget(change.nextState);
  }

  /// Timer ensures we aren't caching constantly.
  Timer? _cacheTimer;

  /// Caches the current state to local storage.
  Future<void> _cacheData(TasksState state) async {
    if (_cacheTimer?.isActive == true) {
      _cacheTimer?.cancel();
      _cacheTimer = null;
    }

    _cacheTimer = Timer(const Duration(seconds: 10), () async {
      final taskListsJson = <String>[];
      for (var taskList in state.taskLists) {
        taskListsJson.add(jsonEncode(taskList.toJson()));
      }

      await StorageRepository.instance.save(
        key: 'taskListsJson',
        value: taskListsJson,
        storageArea: 'cache',
      );
    });
  }

  /// Stream subscription for listening for when the user taps on a notification.
  StreamSubscription<NotificationResponse>? _notificationResponseSubscription;

  /// Listens for when the user taps on a notification.
  void _listenForNotificationResponse() {
    _notificationResponseSubscription = notificationResponseStream.stream
        .listen((NotificationResponse response) async {
      if (response.payload == null) return;

      final task = Task.fromJson(
        jsonDecode(response.payload!) as Map<String, dynamic>,
      );

      switch (response.notificationResponseType) {
        case NotificationResponseType.selectedNotification:
          // The user tapped on the notification.
          setActiveList(task.taskListId);
          setActiveTask(task.id);
          break;
        case NotificationResponseType.selectedNotificationAction:
          // The user tapped on an action button on the notification.
          switch (response.actionId) {
            case 'complete':
              await updateTask(task.copyWith(completed: true));
              break;
            case 'snooze':
              await NotificationsCubit.instance.snoozeTask(task);
              break;
          }
          break;
      }
    });
  }

  /// Updates the Android home screen widget.
  void _updateAndroidWidget(TasksState data) {
    final selectedListId = settingsCubit.state.homeWidgetSelectedListId;
    final selectedList = data //
        .taskLists
        .singleWhereOrNull(
      (taskList) => taskList.id == selectedListId,
    );
    if (selectedList == null) return;

    // Make a copy so we don't affect the actual list while preparing for
    // widget.
    final TaskList listCopy = selectedList.copyWith(
      // Don't show completed/deleted items in widget.
      items: selectedList.items
          .where((e) => !e.completed && e.parent == null)
          .toList(),
    );
    updateHomeWidget('selectedList', jsonEncode(listCopy.toJson()));
  }

  @override
  Future<void> close() {
    _notificationResponseSubscription?.cancel();
    _cacheTimer?.cancel();
    _clearTimer?.cancel();
    return super.close();
  }
}
