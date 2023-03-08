part of 'tasks_cubit.dart';

@freezed
class TasksState with _$TasksState {
  const factory TasksState({
    TaskList? activeList,
    Task? activeTask,
    @Default(false) bool awaitingClearTasksUndo,
    required bool loading,
    required List<TaskList> taskLists,
  }) = _TasksState;

  factory TasksState.empty() {
    return const TasksState(
      awaitingClearTasksUndo: false,
      loading: false,
      taskLists: [],
    );
  }
}
