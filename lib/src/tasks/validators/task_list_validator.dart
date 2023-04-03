import '../tasks.dart';

class TaskListValidator {
  static List<Task> validateTasks({
    required String taskListId,
    required List<Task> tasks,
  }) {
    List<Task> validatedTasks = _validateTaskListIds(taskListId, tasks);
    validatedTasks = _tasksInOrder(validatedTasks);
    return validatedTasks;
  }

  /// Sort tasks as top-level before sub-tasks, both in order by index.
  static List<Task> _tasksInOrder(List<Task> tasks) {
    final sortedTasks = List<Task>.from(tasks);
    sortedTasks.sort((a, b) {
      if (a.parent != null && b.parent == null) {
        return 1;
      }

      if (a.parent == null && b.parent != null) {
        return -1;
      }

      return a.index.compareTo(b.index);
    });
    return sortedTasks;
  }

  /// Validate that all tasks have their taskListId set.
  static List<Task> _validateTaskListIds(
    String taskListId,
    List<Task> tasks,
  ) {
    final validatedTasks = <Task>[];
    for (var task in tasks) {
      if (task.taskListId == taskListId) {
        validatedTasks.add(task);
      } else {
        validatedTasks.add(task.copyWith(taskListId: taskListId));
      }
    }
    return validatedTasks;
  }
}
