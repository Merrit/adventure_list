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

  factory TasksState.initial() {
    return const TasksState(
      awaitingClearTasksUndo: false,
      loading: true,
      taskLists: [],
    );
  }

  factory TasksState.fromJson(Map<String, dynamic> json) => _$TasksStateFromJson(json);
}
