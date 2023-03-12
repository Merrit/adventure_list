import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../tasks.dart';

part 'task_list.freezed.dart';
part 'task_list.g.dart';

/// A Todo list.
///
/// Analogous to a `Calendar` object from the Google Calendar API.
@freezed
class TaskList with _$TaskList {
  /// Private empty constructor enables methods on Freezed classes.
  const TaskList._();

  const factory TaskList._internal({
    /// Identifier of the calendar.
    required String id,

    /// Index of the [TaskList] in the list of [TaskList]s.
    required int index,

    /// Tasks in the list.
    required List<Task> items,

    /// True if local changes have been synced to remote server.
    @JsonKey(defaultValue: false) required bool synced,

    /// Title of the list.
    required String title,
  }) = _TaskList;

  factory TaskList({
    required List<Task> items,
    required String id,
    required int index,
    bool synced = false,
    required String title,
  }) {
    return TaskList._internal(
      id: id,
      index: index,
      items: TaskListValidator.tasksInOrder(items),
      synced: synced,
      title: title,
    );
  }

  factory TaskList.fromJson(Map<String, dynamic> json) =>
      _$TaskListFromJson(json);

  factory TaskList.empty() {
    return TaskList(
      id: '',
      index: -1,
      items: const [],
      synced: false,
      title: '',
    );
  }

  /// Task from [oldIndex] is moved to [newIndex].
  ///
  /// Task indexes are recalculated and the updated [TaskList] is returned.
  TaskList reorderTasks(int oldIndex, int newIndex) {
    final updatedTasks = List<Task>.from(items);
    final topLevelTasks = updatedTasks
        .where((element) => element.parent == null && !element.deleted)
        .toList();

    for (var task in topLevelTasks) {
      updatedTasks.remove(task);
    }

    final task = topLevelTasks.removeAt(oldIndex);
    topLevelTasks.insert(newIndex, task);

    for (var i = 0; i < topLevelTasks.length; i++) {
      topLevelTasks[i] = topLevelTasks[i].copyWith(index: i);
    }

    updatedTasks.addAll(topLevelTasks);

    return copyWith(items: updatedTasks);
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

extension TaskListHelper on List<TaskList> {
  /// Returns a copy of the list.
  List<TaskList> copy() => List<TaskList>.from(this);

  /// Returns the [TaskList] with the given [id].
  TaskList? getTaskListById(String id) {
    return firstWhereOrNull((element) => element.id == id);
  }

  /// Returns the [Task] with the given [id].
  Task? getTaskById(String id) {
    for (var taskList in this) {
      final task = taskList.items.taskById(id);
      if (task != null) {
        return task;
      }
    }
    return null;
  }

  /// Returns the [TaskList] with the given [index].
  TaskList? getTaskListByIndex(int index) {
    return firstWhereOrNull((element) => element.index == index);
  }

  /// Sorts [TaskList]s by their index.
  List<TaskList> sorted() {
    sort((a, b) => a.index.compareTo(b.index));
    return this;
  }

  /// Returns a copy of the list with the given [taskList] added.
  List<TaskList> addTaskList(TaskList taskList) {
    final updatedTaskLists = List<TaskList>.from(this);
    updatedTaskLists.add(taskList);
    return updatedTaskLists;
  }

  /// Returns a copy of the list with the given [taskList] removed.
  List<TaskList> removeTaskList(TaskList taskList) {
    final updatedTaskLists = List<TaskList>.from(this);
    updatedTaskLists.remove(taskList);
    return updatedTaskLists;
  }

  /// Returns a copy of the list with the given [TaskList] updated.
  ///
  /// If the [TaskList] does not exist, it is added.
  /// If the [TaskList] exists, it is replaced.
  List<TaskList> updateTaskList(TaskList taskList) {
    final updatedTaskLists = List<TaskList>.from(this);
    final existingTaskList = updatedTaskLists.getTaskListById(taskList.id);
    if (existingTaskList != null) {
      updatedTaskLists.remove(existingTaskList);
    }
    updatedTaskLists.add(taskList);
    return updatedTaskLists;
  }

  /// Returns a copy of the list with the given [task] added.
  List<TaskList> addTask(Task task) {
    final updatedTaskLists = List<TaskList>.from(this);
    final taskList = updatedTaskLists.getTaskListById(task.taskListId);
    if (taskList != null) {
      updatedTaskLists.remove(taskList);
      updatedTaskLists
          .add(taskList.copyWith(items: taskList.items.addTask(task)));
    }
    return updatedTaskLists;
  }

  /// Returns a copy of the list with the given [task] removed.
  List<TaskList> removeTask(Task task) {
    final updatedTaskLists = List<TaskList>.from(this);
    final taskList = updatedTaskLists.getTaskListById(task.taskListId);
    if (taskList != null) {
      updatedTaskLists.remove(taskList);
      updatedTaskLists
          .add(taskList.copyWith(items: taskList.items.removeTask(task)));
    }
    return updatedTaskLists;
  }

  /// Returns a copy of the list with the given [task] updated.
  ///
  /// If the [task] does not exist, it is added.
  /// If the [task] exists, it is replaced.
  List<TaskList> updateTask(Task task) {
    final updatedTaskLists = List<TaskList>.from(this);
    final taskList = updatedTaskLists.getTaskListById(task.taskListId);
    if (taskList != null) {
      updatedTaskLists.remove(taskList);
      updatedTaskLists
          .add(taskList.copyWith(items: taskList.items.updateTask(task)));
    }
    return updatedTaskLists;
  }

  /// Returns a copy of the list with the given [task] reordered.
  List<TaskList> reorderTask(Task task, int newIndex) {
    final updatedTaskLists = List<TaskList>.from(this);
    final taskList = updatedTaskLists.getTaskListById(task.taskListId);
    if (taskList != null) {
      updatedTaskLists.remove(taskList);
      updatedTaskLists.add(
        taskList.copyWith(
          items: taskList.items.reorderTasks(task, newIndex),
        ),
      );
    }
    return updatedTaskLists;
  }
}
