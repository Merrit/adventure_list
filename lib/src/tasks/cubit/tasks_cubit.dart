import 'dart:io';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
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
    final List<String> cache = List<String>.from(
      await _storageService.getStorageAreaValues('cache'),
    );

    final List<TaskList> taskLists = cache //
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

    // Make sure tasks are in order by index.
    for (var i = 0; i < taskLists.length; i++) {
      final taskList = taskLists[i];
      taskLists[i] = taskList.copyWith(items: _tasksInOrder(taskList.items));
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
    final newList = await _tasksRepository.createList(title: title);
    emit(state.copyWith(
      taskLists: List<TaskList>.from(state.taskLists)..add(newList),
      activeList: newList,
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
    final int parentTaskIndex = state.activeList!.items
        .indexWhere((element) => element.id == newTask.parent);
    final Task? parentTask = state.activeList!.items
        .singleWhereIndexedOrNull((index, element) => index == parentTaskIndex);

    int index;
    if (isSubTask) {
      index = parentTask!.subTasks.length;
    } else {
      index = state.activeList!.items.length;
    }

    newTask = await _tasksRepository.createTask(
      taskListId: state.activeList!.id,
      newTask: newTask.copyWith(index: index),
    );

    final updatedItems = List<Task>.from(state.activeList!.items);
    if (isSubTask) {
      updatedItems[parentTaskIndex] = parentTask!.copyWith(
        subTasks: [...parentTask.subTasks, newTask],
      );
    } else {
      updatedItems.add(newTask);
    }

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

  List<Task> _tasksInOrder(List<Task> tasks) {
    // Verify each task has a unique index.
    if (tasks.map((e) => e.index).toSet().length != tasks.length) {
      tasks = _assignTaskIndexes(tasks);
    }
    tasks.sort((a, b) => a.index.compareTo(b.index));
    return tasks;
  }

  List<Task> _assignTaskIndexes(List<Task> tasks) {
    for (var i = 0; i < tasks.length; i++) {
      tasks[i] = tasks[i].copyWith(index: i);
    }
    return tasks;
  }

  /// Called when the user is reordering the list of TaskLists.
  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    List<Task> tasks = List<Task>.from(state.activeList!.items)
      ..removeAt(oldIndex)
      ..insert(newIndex, state.activeList!.items[oldIndex]);
    for (var i = 0; i < tasks.length; i++) {
      tasks[i] = tasks[i].copyWith(index: i);
    }
    final updatedActiveList = state.activeList?.copyWith(items: tasks);
    final activeListIndex = state //
        .taskLists
        .indexWhere((element) => element.id == updatedActiveList?.id);
    final updatedTaskLists = List<TaskList>.from(state.taskLists)
      ..removeAt(activeListIndex)
      ..insert(activeListIndex, updatedActiveList!);
    emit(state.copyWith(
      activeList: updatedActiveList,
      taskLists: updatedTaskLists,
    ));
    await _tasksRepository.updateTask(
      taskListId: state.activeList!.id,
      updatedTask: tasks[oldIndex],
    );
    await _tasksRepository.updateTask(
      taskListId: state.activeList!.id,
      updatedTask: tasks[newIndex],
    );
  }

  Future<Task> updateTask(Task task) async {
    // If the task is unchanged, don't do anything.
    if (state.activeList!.items.contains(task)) return task;

    final activeTask = (state.activeTask?.id == task.id) ? task : null;
    final int index = state.activeList!.items.indexWhere(
      (element) => element.id == task.id,
    );

    // Update local state immediately.
    var items = List<Task>.from(state.activeList!.items)
      ..removeAt(index)
      ..insert(index, task);
    emit(state.copyWith(
      activeList: state.activeList!.copyWith(items: items),
      activeTask: activeTask,
    ));

    final updatedTaskFromRepo = await _tasksRepository.updateTask(
      taskListId: state.activeList!.id,
      updatedTask: task,
    );

    // Update local state with final remote changes.
    items.removeAt(index);
    items.insert(index, updatedTaskFromRepo);
    emit(state.copyWith(
      activeList: state.activeList!.copyWith(items: items),
      activeTask: activeTask,
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
      // Clear sub-tasks for a given parent task.
      if (task.id == parentId) {
        return task.clearCompletedSubTasks();
      }

      /// If we were provided a parentId, we are only affecting tasks associated
      /// with *that* task and its sub-tasks.
      if (parentId != null) {
        return task;
      }

      if (task.completed) {
        // If a parent task is being completed, sub-tasks should be as well.
        final withSubTasksCompleted = task.clearAllSubTasks();
        return withSubTasksCompleted.copyWith(deleted: true);
      } else {
        return task;
      }
    }).toList();

    final TaskList updatedList = state //
        .activeList!
        .copyWith(items: _tasksInOrder(updatedTasks));
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
    _cacheData(change.nextState);

    if (Platform.isAndroid) _updateAndroidWidget(change.nextState);

    super.onChange(change);
  }

  Future<void> _cacheData(TasksState state) async {
    final entries = {};
    for (var taskList in state.taskLists) {
      entries[taskList.id] = taskList.toJson();
    }

    await _storageService.saveStorageAreaValues(
      storageArea: 'cache',
      entries: entries,
    );
  }

  void _updateAndroidWidget(TasksState data) {
    final selectedListId = settingsCubit.state.homeWidgetSelectedListId;
    final selectedList = data //
        .taskLists
        .singleWhereOrNull(
      (taskList) => taskList.id == selectedListId,
    );
    if (selectedList != null) {
      updateHomeWidget('selectedList', selectedList.toJson());
    }
  }
}
