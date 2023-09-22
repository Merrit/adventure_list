import '../tasks.dart';

/// A command that deletes all completed tasks in the active task list.
///
/// This command can be undone.
class DeleteCompletedTasksCommand implements Command {
  /// The [TasksCubit] instance that handles updating the task.
  final TasksCubit cubit;

  /// The task list to delete completed tasks from.
  final TaskList taskList;

  /// The original completed tasks before the command was executed.
  final List<Task> _completedTasksBackup = [];

  DeleteCompletedTasksCommand({
    required this.cubit,
    required this.taskList,
  });

  @override
  Future<void> execute() async {
    // Make sure the active list is the list we are deleting completed tasks from.
    assert(cubit.state.activeList?.id == taskList.id);
    _backupCompletedTasks();
    await cubit.deleteCompletedTasks();
  }

  /// Backs up all the tasks that will be deleted, so they can be restored if the command
  /// is undone.
  void _backupCompletedTasks() {
    // Backup all completed tasks in the active list.
    _completedTasksBackup.addAll(
      cubit.state.activeList?.items.completedTasks() ?? [],
    );
    // Backup all sub-tasks of completed tasks in the active list, since they will be
    // deleted as well.
    final List<Task> subTasks = [];
    for (final task in _completedTasksBackup) {
      subTasks.addAll(
        cubit.state.activeList?.items.subtasksOf(task.id) ?? [],
      );
    }
    _completedTasksBackup.addAll(subTasks);
  }

  @override
  Future<void> undo() async {
    for (final task in _completedTasksBackup) {
      await cubit.createTask(task, assignNewId: false);
    }
  }
}
