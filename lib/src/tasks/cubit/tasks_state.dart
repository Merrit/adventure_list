part of 'tasks_cubit.dart';

@freezed
class TasksState with _$TasksState {
  const factory TasksState({
    TaskList? activeList,
    Task? activeTask,
    @Default(false) bool awaitingClearTasksUndo,
    required bool loading,

    /// An error message to display to the user.
    required String? errorMessage,
    required List<TaskList> taskLists,
  }) = _TasksState;

  factory TasksState.initial() {
    return const TasksState(
      awaitingClearTasksUndo: false,
      loading: true,
      errorMessage: null,
      taskLists: [],
    );
  }

  factory TasksState.fromJson(Map<String, dynamic> json) => _$TasksStateFromJson(json);
}
