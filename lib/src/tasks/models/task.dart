import 'dart:math';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'models.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// Represents a "task" or "todo" item.
@freezed
class Task with _$Task {
  /// Private empty constructor required by [Freezed] to enable
  /// getters and methods.
  const Task._();

  const factory Task._internal({
    /// Whether the task is completed.
    @JsonKey(defaultValue: false)
        required bool completed,

    /// Description of the task.
    required String? description,

    /// Due date of the task.
    @JsonKey(
      fromJson: _dueDateFromJson,
      toJson: _dueDateToJson,
    )
        required DateTime? dueDate,

    /// ID of the task.
    @JsonKey(defaultValue: '')
        required String id,

    /// Index of the task in the list.
    @JsonKey(defaultValue: -1)
        required int index,

    /// ID for notifications associated with the task.
    ///
    /// A 32-bit integer as required by the notifications plugin.
    @JsonKey(defaultValue: _generateNotificationId)
        required int notificationId,

    /// The ID of the task considered the parent, only if this task is nested.
    required String? parent,

    /// The repeat interval of the task.
    ///
    /// If null, the task is not recurring.
    @JsonKey(defaultValue: null)
        required RepeatInterval? repeatInterval,

    /// Whether the task has been synced with the server.
    @JsonKey(defaultValue: false)
        required bool synced,

    /// ID of the task list containing the task.
    @JsonKey(defaultValue: '')
        required String taskListId,

    /// Title of the task.
    @JsonKey(defaultValue: '')
        required String title,

    /// Last time the task was updated.
    @JsonKey(
      fromJson: _updatedFromJson,
      toJson: _updatedToJson,
    )
        required DateTime updated,
  }) = _Task;

  factory Task.empty() => Task._internal(
        completed: false,
        description: null,
        dueDate: null,
        id: '',
        index: -1,
        notificationId: _generateNotificationId(),
        parent: null,
        repeatInterval: null,
        synced: false,
        taskListId: '',
        title: '',
        updated: DateTime.now(),
      );

  factory Task({
    bool completed = false,
    String? description,
    DateTime? dueDate,
    String id = '',
    int index = -1,
    int? notificationId,
    String? parent,
    RepeatInterval? repeatInterval,
    bool synced = false,
    required String taskListId,
    required String title,
    DateTime? updated,
  }) {
    if (dueDate != null) {
      // Remove microseconds so serialization will work reliably.
      dueDate = DateTime.fromMillisecondsSinceEpoch(
        dueDate.millisecondsSinceEpoch,
      );
    }

    if (parent == '') parent = null;

    updated ??= DateTime.now();
    // Remove microseconds so serialization will work reliably.
    updated = DateTime.fromMillisecondsSinceEpoch(
      updated.millisecondsSinceEpoch,
    );

    return Task._internal(
      completed: completed,
      description: description,
      dueDate: dueDate,
      id: id,
      index: index,
      notificationId: notificationId ?? _generateNotificationId(),
      parent: parent,
      repeatInterval: repeatInterval,
      synced: synced,
      taskListId: taskListId,
      title: title,
      updated: updated,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  /// Update the due date of the task to the next occurrence.
  ///
  /// If the task is not recurring, the returned task is unchanged.
  ///
  /// If the task is recurring, the returned task has the due date updated to
  /// the next occurrence if the current due date is in the past.
  Task updateDueDate() {
    if (repeatInterval == null) return this;

    final now = DateTime.now();
    if (dueDate == null || dueDate!.isAfter(now)) return this;

    DateTime newDueDate = dueDate!;
    switch (repeatInterval!.unit) {
      case RepeatIntervalUnit.day:
        while (newDueDate.isBefore(now)) {
          newDueDate = newDueDate.add(const Duration(days: 1));
        }
        break;
      case RepeatIntervalUnit.week:
        while (newDueDate.isBefore(now)) {
          newDueDate = newDueDate.add(const Duration(days: 7));
        }
        break;
      case RepeatIntervalUnit.month:
        while (newDueDate.isBefore(now)) {
          // This is not perfect, but it's good enough for now.
          newDueDate = newDueDate.add(const Duration(days: 30));
        }
        break;
      case RepeatIntervalUnit.year:
        while (newDueDate.isBefore(now)) {
          newDueDate = newDueDate.add(const Duration(days: 365));
        }
        break;
    }

    return copyWith(dueDate: newDueDate);
  }
}

/// Handles the fromJson for [Task.dueDate].
DateTime? _dueDateFromJson(int? date) {
  if (date == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(date);
}

/// Handles the toJson for [Task.dueDate].
int? _dueDateToJson(DateTime? date) {
  if (date == null) return null;
  return date.millisecondsSinceEpoch;
}

/// Generate a random id for a notification.
///
/// The id will fit within a 32-bit integer as required by the plugin.
int _generateNotificationId() {
  return Random().nextInt(1 << 30);
}

/// Handles the fromJson for [Task.updated].
DateTime _updatedFromJson(int date) {
  return DateTime.fromMillisecondsSinceEpoch(date);
}

/// Handles the toJson for [Task.updated].
int _updatedToJson(DateTime date) {
  return date.millisecondsSinceEpoch;
}

/// Convenience extension methods for a list of tasks.
extension ListOfTasksExtensions on List<Task> {
  /// Returns a copy of the list with the task added.
  List<Task> addTask(Task task) {
    return [...this, task];
  }

  /// Returns a copy of the list.
  List<Task> copy() {
    return [...this];
  }

  // Returns all [Task]s that are marked as completed.
  List<Task> completedTasks() {
    return where((t) => t.completed).toList();
  }

  /// Returns the task with the given ID, or null if not found.
  Task? getTaskById(String id) {
    return firstWhereOrNull((t) => t.id == id);
  }

  /// Returns all [Task]s that are not marked as completed.
  List<Task> incompleteTasks() {
    return where((t) => !t.completed).toList();
  }

  /// Returns a copy of the list with the task marked as completed.
  List<Task> markTaskCompleted(Task task) {
    return map((t) => t.id == task.id ? task.copyWith(completed: true) : t)
        .toList();
  }

  /// Returns a copy of the list with the task marked as uncompleted.
  List<Task> markTaskNotCompleted(Task task) {
    return map((t) => t.id == task.id ? task.copyWith(completed: false) : t)
        .toList();
  }

  /// Returns all [Task]s that have a due date in the past and are not completed.
  List<Task> overdueTasks() {
    return where((t) =>
        !t.completed &&
        t.dueDate != null &&
        t.dueDate!.isBefore(DateTime.now())).toList();
  }

  /// Returns a copy of the list with the task updated to the new index.
  ///
  /// The index of all the tasks is updated.
  ///
  /// If the task is not in the list, the list is returned unchanged.
  List<Task> reorderTasks(Task task, int newIndex) {
    if (!contains(task)) return this;

    final updatedTasks = [...this];
    updatedTasks.remove(task);
    updatedTasks.insert(newIndex, task);
    for (var i = 0; i < updatedTasks.length; i++) {
      updatedTasks[i] = updatedTasks[i].copyWith(index: i);
    }
    return updatedTasks;
  }

  /// Returns a copy of the list with the task removed.
  ///
  /// If the task has subtasks, they are also removed.
  ///
  /// The index of the remaining tasks is updated.
  List<Task> removeTask(Task task) {
    List<Task> updatedTasks = [...this]
      ..remove(task)
      ..removeWhere((t) => t.parent == task.id);

    updatedTasks = updatedTasks.updateIndexes();
    return updatedTasks;
  }

  /// Returns a copy of the list with all the given [Task]s removed.
  ///
  /// If any of the tasks have subtasks, they are also removed.
  ///
  /// The index of the remaining tasks is updated.
  List<Task> removeTasks(List<Task> tasks) {
    List<Task> updatedTasks = [...this]
      ..removeWhere((t) => tasks.contains(t))
      ..removeWhere((t) => tasks.any((task) => task.id == t.parent));

    updatedTasks = updatedTasks.updateIndexes();
    return updatedTasks;
  }

  /// Returns a copy of the list with tasks sorted by due date.
  List<Task> sortedByDueDate() {
    return [...this]..sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
  }

  /// Returns a copy of the list with tasks sorted by index.
  List<Task> sortedByIndex() {
    return [...this]..sort((a, b) => a.index.compareTo(b.index));
  }

  /// Returns a copy of the list with tasks sorted by title.
  List<Task> sortedByTitle() {
    return [...this]..sort((a, b) => a.title.compareTo(b.title));
  }

  /// Returns a copy of the list with tasks sorted by updated date.
  List<Task> sortedByUpdated() {
    return [...this]..sort((a, b) => b.updated.compareTo(a.updated));
  }

  /// Returns all [Task]s which are subtasks of the [Task] with the given [id].
  List<Task> subtasksOf(String id) {
    return where((t) => t.parent == id).toList();
  }

  /// Returns all top-level [Task]s.
  List<Task> topLevelTasks() {
    return where((t) => t.parent == null).toList();
  }

  /// Returns a copy of the list with the task indexes updated.
  ///
  /// Subtasks have a separate index than top-level tasks.
  List<Task> updateIndexes() {
    final updatedTasks = <Task>[];

    // Update the top-level tasks.
    final topLevelTasks = this.topLevelTasks();
    for (var i = 0; i < topLevelTasks.length; i++) {
      topLevelTasks[i] = topLevelTasks[i].copyWith(index: i);
    }
    updatedTasks.addAll(topLevelTasks);

    // Update the subtasks.
    for (var task in topLevelTasks) {
      final subtasks = subtasksOf(task.id);
      for (var i = 0; i < subtasks.length; i++) {
        subtasks[i] = subtasks[i].copyWith(index: i);
      }
      updatedTasks.addAll(subtasks);
    }

    return updatedTasks;
  }

  /// Returns a copy of the list with the task updated.
  List<Task> updateTask(Task task) {
    return map((t) => t.id == task.id ? task : t).toList();
  }
}
