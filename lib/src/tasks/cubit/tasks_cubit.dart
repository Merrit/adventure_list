import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:uuid/uuid.dart';

import '../../authentication/authentication.dart';
import '../../home_widget/home_widget_manager.dart';
import '../../logs/logs.dart';
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

    Timer.periodic(
      const Duration(minutes: 1),
      (timer) => syncWithRepo(),
    );
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
    final List<TaskList> lists = state.taskLists.copy()
      ..removeAt(oldIndex)
      ..insert(newIndex, state.taskLists[oldIndex]);
    for (var i = 0; i < lists.length; i++) {
      lists[i] = lists[i].copyWith(index: i, synced: false);
    }
    final String? activeListId = state.activeList?.id;
    emit(state.copyWith(
      taskLists: lists,
      activeList: lists.singleWhereOrNull((e) => e.id == activeListId),
    ));
  }

  void setActiveList(String id) {
    final list = state.taskLists.singleWhere((element) => element.id == id);
    emit(state.copyWith(
      activeList: list,
      activeTask: state.activeTask?.copyWith(id: ''),
    ));
    StorageRepository.instance.save(key: 'activeList', value: id);
  }

  /// Updates the provided [TaskList].
  Future<void> updateList(TaskList list) async {
    list = list.copyWith(synced: false);
    final updatedLists = state.taskLists.copy()
      ..removeWhere((element) => element.id == list.id)
      ..add(list);

    final TaskList? activeList =
        (list.id == state.activeList?.id) ? list : null;

    emit(state.copyWith(
      activeList: activeList,
      taskLists: updatedLists.sorted(),
    ));

    await _tasksRepository.updateList(list: list);
  }

  /// Creates a new [Task].
  Future<Task> createTask(Task newTask) async {
    assert(state.activeList != null);

    final tempId = _uuid.v4();
    newTask = newTask.copyWith(id: tempId);

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

    // Emit local cached task immediately.
    newTask = newTask.copyWith(index: index);
    List<Task> updatedItems = List<Task>.from(state.activeList!.items) //
      ..add(newTask);
    TaskList updatedList = state.activeList!.copyWith(items: updatedItems);
    List<TaskList> updatedTaskLists = state.taskLists.copy()
      ..remove(state.activeList)
      ..add(updatedList);

    emit(state.copyWith(
      activeList: updatedList,
      taskLists: updatedTaskLists.sorted(),
    ));

    // Create task with repository to get final id.
    // TODO: Move to a batching / cache method on a timer.
    final newTaskFromRepo = await _tasksRepository.createTask(
      taskListId: state.activeList!.id,
      newTask: newTask,
    );

    updatedItems = List<Task>.from(updatedList.items) //
      ..removeWhere((e) => e.id == tempId)
      ..add(newTaskFromRepo!);
    updatedList = updatedList.copyWith(items: updatedItems);
    updatedTaskLists = state.taskLists.copy()
      ..remove(state.activeList)
      ..add(updatedList);

    emit(state.copyWith(
      activeList: updatedList,
      taskLists: updatedTaskLists.sorted(),
    ));

    return newTaskFromRepo;
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
    // If the task is unchanged, don't do anything.
    if (state.activeList!.items.contains(task)) return task;

    final bool isActiveTask = (state.activeTask?.id == task.id);
    final int index = state.activeList!.items.indexWhere(
      (element) => element.id == task.id,
    );

    // Update local state immediately.
    final items = List<Task>.from(state.activeList!.items)
      ..removeAt(index)
      ..insert(index, task);
    final int taskListIndex = state.taskLists.indexWhere(
      (element) => element.id == state.activeList!.id,
    );
    final TaskList updatedTaskList = state //
        .taskLists[taskListIndex]
        .copyWith(items: items);
    final List<TaskList> updatedAllTaskLists = state.taskLists.copy()
      ..[taskListIndex] = updatedTaskList;

    emit(state.copyWith(
      activeList: updatedTaskList,
      activeTask: isActiveTask ? task : null,
      taskLists: updatedAllTaskLists,
    ));

    // Save task to be batch synced periodically.
    await StorageRepository.instance.save(
      key: task.id,
      value: {
        'taskListId': updatedTaskList.id,
        'task': task.toJson(),
      },
      storageArea: 'tasksToBeSynced',
    );

    return task;
  }

  /// Sync all lists with changes to the remote repository.
  Future<void> _syncUpdatedLists() async {
    final Iterable<TaskList> listsToBeSynced = state.taskLists //
        .where((element) => !element.synced);
    final taskLists = [...state.taskLists];

    for (var list in listsToBeSynced) {
      await _tasksRepository.updateList(list: list);

      final int index = taskLists.indexWhere((e) => e.id == list.id);
      taskLists[index] = list.copyWith(synced: true);
    }

    emit(state.copyWith(taskLists: taskLists));
  }

  /// Sync all tasks with changes to the remote repository.
  Future<void> _syncUpdatedTasks() async {
    final tasksToBeSynced =
        await StorageRepository.instance.getStorageAreaValues(
      'tasksToBeSynced',
    );

    for (var taskEntry in tasksToBeSynced) {
      final taskListId = taskEntry['taskListId'] as String;
      final taskJson = taskEntry['task'] as Map<String, dynamic>;

      final task = Task.fromJson(taskJson);

      await _tasksRepository.updateTask(
        taskListId: taskListId,
        updatedTask: task,
      );

      await StorageRepository.instance.delete(
        task.id,
        storageArea: 'tasksToBeSynced',
      );
    }
  }

  /// Sync all changes to the remote repository.
  Future<void> syncWithRepo() async {
    await _syncUpdatedLists();
    await _syncUpdatedTasks();
  }

  /// Sets the [Task] with the provided [id] as the active task.
  void setActiveTask(String? id) {
    emit(state.copyWith(
      activeTask: state.activeList?.items.singleWhereOrNull((e) => e.id == id),
    ));
  }

  /// True if the user cancelled the clear operation.
  bool _clearTasksWasCancelled = false;

  /// The [TaskList] before the user cleared completed tasks.
  TaskList? _activeTaskListBeforeClear;

  /// The [TaskList] collection before the user cleared completed tasks.
  List<TaskList>? _taskListCollectionBeforeClear;

  /// Clears all completed tasks from the active list.
  Future<void> clearCompletedTasks([String? parentId]) async {
    _clearTasksWasCancelled = false;

    // A task is marked "completed" when it is checked, but this does not remove
    // it from the list. By "clearing" we are also setting the "deleted"
    // property to true - which doesn't *actually* delete it, but hides it. This
    // gives us the option of retrieving "deleted" items.

    _activeTaskListBeforeClear = state.activeList!.copyWith();
    _taskListCollectionBeforeClear = state.taskLists.copy();

    final List<Task> updatedTasks = state.activeList!.items.map((Task task) {
      final Task? parent = state //
          .activeList
          ?.items
          .singleWhereOrNull((element) => element.id == task.parent);

      // If a parent task is being completed, sub-tasks should be as well.
      if (parent != null && parent.completed) {
        return task.copyWith(completed: true, deleted: true);
      }

      // Not completed.
      if (!task.completed) return task;

      // Completed top-level tasks.
      if (parentId == null && task.parent == null) {
        return task.copyWith(deleted: true);
      }

      // Completed sub-tasks.
      if (parentId != null && task.parent == parentId) {
        return task.copyWith(deleted: true);
      }

      // Default.
      return task;
    }).toList();

    final TaskList updatedList = state //
        .activeList!
        .copyWith(items: updatedTasks);
    final int index = state.taskLists.indexWhere((e) => e.id == updatedList.id);

    final taskLists = state.taskLists.copy()
      ..removeAt(index)
      ..insert(index, updatedList);

    emit(state.copyWith(
      activeList: updatedList,
      awaitingClearTasksUndo: true,
      taskLists: taskLists.sorted(),
    ));

    // Give the user a chance to undo.
    await Future.delayed(const Duration(seconds: 5));
    emit(state.copyWith(awaitingClearTasksUndo: false));

    if (!_clearTasksWasCancelled) {
      // Ensure pending task updates don't overwrite the cleared state.
      for (var task in updatedList.items) {
        await StorageRepository.instance.delete(
          task.id,
          storageArea: 'tasksToBeSynced',
        );
      }

      // Commit to clearing changes.
      for (var task in updatedList.items) {
        await _tasksRepository.updateTask(
          taskListId: updatedList.id,
          updatedTask: task,
        );
      }
    }
  }

  /// Cancels the clear operation.
  void undoClearTasks() {
    _clearTasksWasCancelled = true;
    emit(state.copyWith(
      activeList: _activeTaskListBeforeClear,
      awaitingClearTasksUndo: false,
      taskLists: _taskListCollectionBeforeClear!,
    ));
  }

  @override
  void onChange(Change<TasksState> change) {
    if (change.currentState != change.nextState) {
      _cacheData(change.nextState);
    }

    if (Platform.isAndroid) _updateAndroidWidget(change.nextState);

    super.onChange(change);
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
      items: List<Task>.from(selectedList.items),
    );
    // Don't show completed/deleted items in widget.
    listCopy //
        .items
        .removeWhere((e) => e.completed || e.deleted || e.parent != null);
    updateHomeWidget('selectedList', listCopy.toJson());
  }
}
