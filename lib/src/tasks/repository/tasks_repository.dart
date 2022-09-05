import '../tasks.dart';

/// Abstract interface for task repositories.
abstract class TasksRepository {
  /// Fetch all of the user's [TaskList]s.
  Future<List<TaskList>> getAll();

  /// Create a new [TaskList].
  Future<TaskList> createList(TaskList taskList);

  /// Delete the [TaskList] with [id].
  Future<void> deleteList({required String id});

  /// Update the provided [TaskList] in the repository.
  Future<void> updateList({required TaskList list});

  /// Create a new [Task].
  Future<Task> createTask({
    required String taskListId,
    required Task newTask,
  });

  /// Update the provided [Task] in the repository.
  Future<Task> updateTask({
    required String taskListId,
    required Task updatedTask,
  });
}
