import '../tasks.dart';

/// A command that sets the completed status of a task.
///
/// If the task is recurring, the due date will be updated to the next occurrence and the
/// completion status will not be updated.
///
/// If the task is not recurring, the completion status will be updated and any sub-tasks
/// will be updated as well.
///
/// This command can be undone.
class SetTaskCompletedCommand implements Command {
  /// The [TasksCubit] instance that handles updating the task.
  final TasksCubit cubit;

  /// The task to update.
  final Task task;

  /// The new completed status of the task.
  final bool completed;

  SetTaskCompletedCommand({
    required this.cubit,
    required this.task,
    required this.completed,
  }) : _subTasksBackup = cubit.state.taskLists
                .getTaskListById(task.taskListId)
                ?.items
                .subtasksOf(task.id) ??
            [];

  /// The original sub-tasks before the command was executed.
  final List<Task> _subTasksBackup;

  @override
  Future<void> execute() async {
    // If the task is recurring, update the due date to the next occurrence.
    if (task.recurrenceRule != null) {
      await cubit.updateTaskToNextOccurrence(task);
      return;
    }

    // If the task is not recurring, update the completion status.
    await cubit.updateTask(task.copyWith(completed: completed));

    // If the task has sub-tasks, update their completion status as well.
    for (final subTask in _subTasksBackup) {
      await cubit.updateTask(subTask.copyWith(completed: completed));
    }
  }

  @override
  Future<void> undo() async {
    await cubit.updateTask(task.copyWith(completed: !completed));

    for (final subTask in _subTasksBackup) {
      await cubit.updateTask(subTask.copyWith(completed: !completed));
    }
  }
}
