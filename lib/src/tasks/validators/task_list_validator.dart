import '../tasks.dart';

class TaskListValidator {
  /// Sort tasks as top-level before sub-tasks, both in order by index.
  static List<Task> tasksInOrder(List<Task> tasks) {
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
}
