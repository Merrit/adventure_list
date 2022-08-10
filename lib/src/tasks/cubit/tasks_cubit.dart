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
    this._storageService,
  ) : super(TasksState.empty()) {
    tasksCubit = this;

    // If already signed in, initialize the tasks.
    if (authCubit.state.signedIn) {
      _getTasksRepo(authCubit.state.accessCredentials!);
    }

    authCubit.stream.listen((AuthenticationState authState) async {
      // If sign in happens after cubit is created, initialize the tasks.
      if (authState.signedIn) {
        _getTasksRepo(authCubit.state.accessCredentials!);
      }
    });
  }

  // This should be injected so we can do mocks / tests.
  Future<void> _getTasksRepo(AccessCredentials credentials) async {
    final tasksRepository = await GoogleCalendar.initialize(
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
      await authCubit.logout();
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
    await _tasksRepository.updateList(list: list);
    final taskLists = List<TaskList>.from(state.taskLists);
    emit(state.copyWith(
      activeList: taskLists.singleWhereOrNull(
        (e) => e.id == state.activeList?.id,
      ),
      taskLists: _listsInOrder(taskLists),
    ));
  }

  Future<void> createTask(Task newTask) async {
    assert(state.activeList != null);

    newTask = await _tasksRepository.createTask(
      taskListId: state.activeList!.id,
      newTask: newTask,
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
  }

  Future<void> updateTask(Task task) async {
    // If the task is unchanged, don't do anything.
    if (state.activeList!.items.contains(task)) return;

    final int index = state.activeList!.items.indexWhere(
      (element) => element.id == task.id,
    );

    var items = List<Task>.from(state.activeList!.items)
      ..removeAt(index)
      ..insert(index, task);
    emit(state.copyWith(activeList: state.activeList!.copyWith(items: items)));

    final updatedTaskFromRepo = await _tasksRepository.updateTask(
      taskListId: state.activeList!.id,
      updatedTask: task,
    );

    items.removeAt(index);
    items.insert(index, updatedTaskFromRepo);
    emit(state.copyWith(activeList: state.activeList!.copyWith(items: items)));
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

  Future<void> clearCompletedTasks() async {
    // If the task is "completed", we also mark it "deleted".
    final TaskList updatedList = state.activeList!.copyWith(
      items: state.activeList!.items
          .map((e) => e.copyWith(deleted: e.completed))
          .toList(),
    );

    final taskLists = List<TaskList>.from(state.taskLists)
      ..removeWhere((element) => element.id == updatedList.id)
      ..add(updatedList);

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
    if (Platform.isAndroid) {
      final data = change.nextState;
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

    super.onChange(change);
  }
}
