import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../tasks.dart';

part 'tasks_state.dart';

late TasksCubit tasksCubit;

class TasksCubit extends Cubit<TasksState> {
  final TasksRepository _tasksRepository;

  TasksCubit(
    this._tasksRepository,
  ) : super(const TasksState(loading: true, taskLists: [])) {
    tasksCubit = this;
    initialize();
  }

  Future<void> initialize() async {
    final tasks = await _tasksRepository.getAll();
    emit(state.copyWith(loading: false, taskLists: tasks));
  }

  void setActiveList(String id) {
    final list = state.taskLists.singleWhere((element) => element.id == id);
    emit(state.copyWith(activeList: list));
  }

  Future<void> createList(String title) async {
    final newList = await _tasksRepository.createList(title: title);
    emit(state.copyWith(
      taskLists: List<TaskList>.from(state.taskLists)..add(newList),
      activeList: newList,
    ));
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

    var items = List<Task>.from(state.activeList!.items)
      ..removeWhere((element) => element.id == task.id)
      ..add(task);
    emit(state.copyWith(activeList: state.activeList!.copyWith(items: items)));
    final updatedTaskFromRepo = await _tasksRepository.updateTask(
      calendarId: state.activeList!.id,
      updatedTask: task,
    );
    items.removeWhere((element) => element.id == updatedTaskFromRepo.id);
    items.add(updatedTaskFromRepo);
    emit(state.copyWith(activeList: state.activeList!.copyWith(items: items)));
  }
}
