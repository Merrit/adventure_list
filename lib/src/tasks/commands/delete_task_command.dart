import '../tasks.dart';

/// A command that deletes the specified task.
///
/// This command can be undone.
class DeleteTaskCommand implements Command {
  /// The [TasksCubit] instance that handles updating the task.
  final TasksCubit cubit;

  /// The task to delete.
  final Task task;

  DeleteTaskCommand({
    required this.cubit,
    required this.task,
  });

  @override
  Future<void> execute() async {
    if (cubit.state.activeTask?.id == task.id) {
      cubit.setActiveTask(null);
    }

    await cubit.deleteTask(task);
  }

  @override
  Future<void> undo() async {
    await cubit.createTask(task, assignNewId: false);
  }
}
