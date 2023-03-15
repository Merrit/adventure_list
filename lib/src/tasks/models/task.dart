import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// Represents a "task" or "todo" item.
@freezed
class Task with _$Task {
  const factory Task._({
    /// Whether the task is completed.
    @JsonKey(defaultValue: false)
        required bool completed,

    /// Whether the task is deleted.
    @JsonKey(defaultValue: false)
        required bool deleted,

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

    /// The ID of the task considered the parent, only if this task is nested.
    required String? parent,

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

  factory Task.empty() => Task._(
        completed: false,
        deleted: false,
        description: null,
        dueDate: null,
        id: '',
        index: -1,
        parent: null,
        synced: false,
        taskListId: '',
        title: '',
        updated: DateTime.now(),
      );

  factory Task({
    bool completed = false,
    bool deleted = false,
    String? description,
    DateTime? dueDate,
    String id = '',
    int index = -1,
    String? parent,
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

    return Task._(
      completed: completed,
      deleted: deleted,
      description: description,
      dueDate: dueDate,
      id: id,
      index: index,
      parent: parent,
      synced: synced,
      taskListId: taskListId,
      title: title,
      updated: updated,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
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

  /// Returns all [Task]s which are deleted.
  List<Task> deletedTasks() {
    return where((t) => t.deleted).toList();
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

  /// Returns a copy of the list with the task marked as deleted.
  ///
  /// The task is not actually removed from the list.
  List<Task> markTaskDeleted(Task task) {
    return map((t) => t.id == task.id ? task.copyWith(deleted: true) : t)
        .toList();
  }

  /// Returns a copy of the list with the task marked as undeleted.
  List<Task> markTaskNotDeleted(Task task) {
    return map((t) => t.id == task.id ? task.copyWith(deleted: false) : t)
        .toList();
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
  /// The index of the remaining tasks is updated.
  List<Task> removeTask(Task task) {
    final updatedTasks = [...this];
    updatedTasks.remove(task);
    for (var i = 0; i < updatedTasks.length; i++) {
      updatedTasks[i] = updatedTasks[i].copyWith(index: i);
    }
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

  /// Returns a copy of the list with the task updated.
  List<Task> updateTask(Task task) {
    return map((t) => t.id == task.id ? task : t).toList();
  }
}
