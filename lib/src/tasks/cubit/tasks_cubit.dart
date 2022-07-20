import 'dart:io';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../../authentication/cubit/authentication_cubit.dart';
import '../../home_widget/home_widget_manager.dart';
import '../../storage/storage_service.dart';
import '../tasks.dart';

part 'tasks_state.dart';

late TasksCubit tasksCubit;

class TasksCubit extends Cubit<TasksState> {
  final _log = Logger('TasksCubt');

  final StorageService _storageService;
  final TasksRepository _tasksRepository;

  TasksCubit(
    this._storageService,
    this._tasksRepository,
  ) : super(const TasksState(loading: true, taskLists: [])) {
    tasksCubit = this;
    initialize();
  }

  Future<void> initialize() async {
    List<TaskList> taskLists;
    try {
      taskLists = await _tasksRepository.getAll();
    } catch (e) {
      _log.warning('Exception while attempting to fetch tasks: $e');
      await authCubit.logout();
      return;
    }

    final String? activeListId = await _storageService.getValue('activeList');
    emit(state.copyWith(
      activeList: taskLists.singleWhereOrNull((e) => e.id == activeListId),
      loading: false,
      taskLists: taskLists,
    ));
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
    emit(state.copyWith(
      /// `copyWith` has a check, so setting `id` to `''` will remove
      /// the active list.
      activeList: activeList.copyWith(id: ''),
      taskLists: updatedLists,
    ));
    await _tasksRepository.deleteList(id: deletionListId);
  }

  void setActiveList(String id) {
    final list = state.taskLists.singleWhere((element) => element.id == id);
    emit(state.copyWith(
      activeList: list,
      activeTask: state.activeTask?.copyWith(id: ''),
    ));
    _storageService.saveValue(key: 'activeList', value: id);
  }

  Future<void> updateList(TaskList list) async {
    await _tasksRepository.updateList(list: list);
    // TODO: Replace this remove/add with by index version once indexes are
    // working.
    final taskLists = List<TaskList>.from(state.taskLists)
      ..removeWhere((element) => element.id == list.id)
      ..add(list);
    emit(state.copyWith(activeList: list, taskLists: taskLists));
  }

  Future<void> createTask(Task newTask) async {
    assert(state.activeList != null);

    newTask = await _tasksRepository.createTask(
      calendarId: state.activeList!.id,
      newTask: newTask,
    );

    final updatedItems = List<Task>.from(state.activeList!.items) //
      ..add(newTask);

    final updatedList = state.activeList!.copyWith(items: updatedItems);
    final updatedTaskLists = List<TaskList>.from(state.taskLists)
      ..remove(state.activeList)
      ..add(updatedList);

    emit(state.copyWith(activeList: updatedList, taskLists: updatedTaskLists));
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
      calendarId: state.activeList!.id,
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

  @override
  void onChange(Change<TasksState> change) {
    if (Platform.isAndroid) {
      final data = change.nextState;
      updateHomeWidget('listNames', data);
    }

    super.onChange(change);
  }
}
