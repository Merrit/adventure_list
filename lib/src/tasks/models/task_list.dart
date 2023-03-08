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
}

extension TaskListHelper on List<TaskList> {
  /// Returns a copy of the list.
  List<TaskList> copy() => List<TaskList>.from(this);

  /// Sorts [TaskList]s by their index.
  List<TaskList> sorted() {
    sort((a, b) => a.index.compareTo(b.index));
    return this;
  }
}
