import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

import '../../authentication/authentication.dart';
import '../../home_widget/home_widget_manager.dart';
import '../../logs/logs.dart';
import '../../settings/settings.dart';
import '../../storage/storage_service.dart';
import '../tasks.dart';

part 'tasks_state.dart';

late TasksCubit tasksCubit;

class TasksCubit extends Cubit<TasksState> {
  final StorageService _storageService;

  TasksCubit(
    AuthenticationCubit authCubit,
    this._storageService, {
    TasksRepository? tasksRepository,
  }) : super(TasksState.empty()) {
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

  Future<void> _getCachedData() async {
    final List<String>? taskListsJson = await _storageService.getValue(
      'taskListsJson',
      storageArea: 'cache',
    );

    if (taskListsJson == null) return;

    final List<TaskList> taskLists = taskListsJson //
        .map((e) => TaskList.fromJson(e))
        .toList();

    final String? activeListId = await _storageService.getValue('activeList');

    emit(state.copyWith(
      activeList: taskLists.singleWhereOrNull((e) => e.id == activeListId),
      loading: false,
      taskLists: _listsInOrder(taskLists),
    ));
  }

  Future<void> _getTasksRepo({
    required AccessCredentials credentials,
    TasksRepository? tasksRepository,
  }) async {
    /// If [tasksRepository] is non-null it was passed in as a mock.
    tasksRepository ??= await GoogleCalendar.initialize(
      clientId: GoogleAuthIds.clientId,
      credentials: credentials,
    );

    initialize(tasksRepository);
  }

  late TasksRepository _tasksRepository;

  Future<void> initialize(TasksRepository tasksRepository) async {
    _tasksRepository = tasksRepository;

    emit(state.copyWith(loading: true));

    List<TaskList> taskLists;
    try {
      taskLists = await _tasksRepository.getAll();
    } catch (e) {
      logger.w('Exception while attempting to fetch tasks: $e');
      // Do we want to sign out??
      // await authCubit.signOut();
      return;
    }

    final String? activeListId = await _storageService.getValue('activeList');
    emit(state.copyWith(
      activeList: taskLists.singleWhereOrNull((e) => e.id == activeListId),
      loading: false,
      taskLists: _listsInOrder(taskLists),
    ));
  }

  List<TaskList> _listsInOrder(List<TaskList> lists) {
    lists.sort((a, b) => a.index.compareTo(b.index));
    return lists;
  }

  Future<void> createList(String title) async {
    // Quickly create a list in memory for good UX.
    TaskList newList = TaskList(
      id: UniqueKey().toString(),
      index: state.taskLists.length,
      items: const [],
      title: title,
    );
    emit(state.copyWith(
      activeList: newList,
      taskLists: List<TaskList>.from(state.taskLists)..add(newList),
    ));

    // Create list properly through repository to get id & etc.
    final newListFromRepo = await _tasksRepository.createList(newList);
    newList = newList.copyWith(id: newListFromRepo.id);

    final taskLists = List<TaskList>.from(state.taskLists);
    if (taskLists.isNotEmpty) taskLists.removeLast();
    taskLists.add(newList);

    emit(state.copyWith(
      activeList: newList,
      taskLists: taskLists,
    ));
  }

  Future<void> deleteList() async {
    final TaskList? activeList = state.activeList;
    if (activeList == null) return;

    final String deletionListId = activeList.id;
    final updatedLists = List<TaskList>.from(state.taskLists)
      ..remove(activeList);
    emit(TasksState(
      activeList: null,
      activeTask: null,
      loading: false,
      taskLists: _listsInOrder(updatedLists),
    ));
    await _tasksRepository.deleteList(id: deletionListId);
  }

  /// Called when the user is reordering the list of TaskLists.
  Future<void> reorderLists(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    List<TaskList> lists = List<TaskList>.from(state.taskLists)
      ..removeAt(oldIndex)
      ..insert(newIndex, state.taskLists[oldIndex]);
    for (var i = 0; i < lists.length; i++) {
      lists[i] = lists[i].copyWith(index: i);
    }
    final String? activeListId = state.activeList?.id;
    emit(state.copyWith(
      taskLists: lists,
      activeList: lists.singleWhereOrNull((e) => e.id == activeListId),
    ));
    await _updateAllLists();
  }

  void setActiveList(String id) {
    final list = state.taskLists.singleWhere((element) => element.id == id);
    emit(state.copyWith(
      activeList: list,
      activeTask: state.activeTask?.copyWith(id: ''),
    ));
    _storageService.saveValue(key: 'activeList', value: id);
  }

  Future<void> _updateAllLists() async {
    for (var list in state.taskLists) {
      await updateList(list);
    }
  }

  Future<void> updateList(TaskList list) async {
    final updatedLists = List<TaskList>.from(state.taskLists)
      ..removeWhere((element) => element.id == list.id)
      ..add(list);

    TaskList? activeList = (list.id == state.activeList?.id) ? list : null;

    emit(state.copyWith(
      activeList: activeList,
      taskLists: _listsInOrder(updatedLists),
    ));

    await _tasksRepository.updateList(list: list);
  }

  Future<Task> createTask(Task newTask) async {
    assert(state.activeList != null);

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

    newTask = await _tasksRepository.createTask(
      taskListId: state.activeList!.id,
      newTask: newTask.copyWith(index: index),
    );

    final updatedItems = List<Task>.from(state.activeList!.items) //
      ..add(newTask);

    final updatedList = state.activeList!.copyWith(items: updatedItems);
    final updatedTaskLists = List<TaskList>.from(state.taskLists)
      ..remove(state.activeList)
      ..add(updatedList);

    emit(state.copyWith(
      activeList: updatedList,
      taskLists: _listsInOrder(updatedTaskLists),
    ));

    return newTask;
  }

  /// Called when the user is reordering the list of TaskLists.
  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    final previousActiveList = state.activeList!;
    final updatedList = state.activeList!.reorderTasks(oldIndex, newIndex);

    final activeListIndex = state //
        .taskLists
        .indexWhere((element) => element.id == state.activeList!.id);
    final updatedTaskLists = List<TaskList>.from(state.taskLists)
      ..removeAt(activeListIndex)
      ..insert(activeListIndex, updatedList);

    emit(state.copyWith(
      activeList: updatedList,
      taskLists: updatedTaskLists,
    ));

    // Find every task that has changed, and update repository.
    final updatedTasks = updatedList.items
        .toSet()
        .difference(previousActiveList.items.toSet())
        .toList();
    for (var task in updatedTasks) {
      await _tasksRepository.updateTask(
        taskListId: state.activeList!.id,
        updatedTask: task,
      );
    }
  }

  Future<Task> updateTask(Task task) async {
    // If the task is unchanged, don't do anything.
    if (state.activeList!.items.contains(task)) return task;

    final bool isActiveTask = (state.activeTask?.id == task.id);
    final int index = state.activeList!.items.indexWhere(
      (element) => element.id == task.id,
    );

    // Update local state immediately.
    var items = List<Task>.from(state.activeList!.items)
      ..removeAt(index)
      ..insert(index, task);
    final int taskListIndex = state.taskLists.indexWhere(
      (element) => element.id == state.activeList!.id,
    );
    TaskList updatedTaskList = state //
        .taskLists[taskListIndex]
        .copyWith(items: items);
    List<TaskList> updatedAllTaskLists = List<TaskList>.from(state.taskLists)
      ..[taskListIndex] = updatedTaskList;

    emit(state.copyWith(
      activeList: updatedTaskList,
      activeTask: isActiveTask ? task : null,
      taskLists: updatedAllTaskLists,
      // taskLists: update the regular list of tasklists!
    ));

    final updatedTaskFromRepo = await _tasksRepository.updateTask(
      taskListId: state.activeList!.id,
      updatedTask: task,
    );

    // Update local state with final remote changes.
    items.removeAt(index);
    items.insert(index, updatedTaskFromRepo);
    updatedTaskList = updatedTaskList.copyWith(items: items);
    updatedAllTaskLists[taskListIndex] = updatedTaskList;
    emit(state.copyWith(
      activeList: state.activeList!.copyWith(items: items),
      activeTask: isActiveTask ? updatedTaskFromRepo : null,
      taskLists: updatedAllTaskLists,
    ));

    return updatedTaskFromRepo;
  }

  void setActiveTask(String? id) {
    if (id == null) {
      emit(state.copyWith(activeTask: Task(title: '', id: '')));
      return;
    }

    emit(state.copyWith(
      activeTask: state.activeList?.items.singleWhereOrNull((e) => e.id == id),
    ));
  }

  Future<void> clearCompletedTasks([String? parentId]) async {
    // A task is marked "completed" when it is checked, but this does not remove
    // it from the list. By "clearing" we are also setting the "deleted"
    // property to true - which doesn't *actually* delete it, but hides it. This
    // gives us the option of retrieving "deleted" items.

    List<Task> updatedTasks = state.activeList!.items.map((Task task) {
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

    final taskLists = List<TaskList>.from(state.taskLists)
      ..removeAt(index)
      ..insert(index, updatedList);

    emit(state.copyWith(
      activeList: updatedList,
      taskLists: _listsInOrder(taskLists),
    ));

    for (var task in updatedList.items) {
      await _tasksRepository.updateTask(
        taskListId: updatedList.id,
        updatedTask: task,
      );
    }
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

  Future<void> _cacheData(TasksState state) async {
    if (_cacheTimer?.isActive == true) {
      _cacheTimer?.cancel();
      _cacheTimer = null;
    }

    _cacheTimer = Timer(const Duration(seconds: 10), () async {
      final taskListsJson = <String>[];
      for (var taskList in state.taskLists) {
        taskListsJson.add(taskList.toJson());
      }

      await _storageService.saveValue(
        key: 'taskListsJson',
        value: taskListsJson,
        storageArea: 'cache',
      );
    });
  }

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
