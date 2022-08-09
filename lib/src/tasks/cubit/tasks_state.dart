part of 'tasks_cubit.dart';

class TasksState extends Equatable {
  final TaskList? activeList;
  final Task? activeTask;
  final bool loading;
  final List<TaskList> taskLists;

  const TasksState({
    this.activeList,
    this.activeTask,
    required this.loading,
    required this.taskLists,
  });

  factory TasksState.empty() {
    return const TasksState(
      loading: false,
      taskLists: [],
    );
  }

  @override
  List<Object?> get props => [activeList, activeTask, loading, taskLists];

  TasksState copyWith({
    TaskList? activeList,
    Task? activeTask,
    bool? loading,
    List<TaskList>? taskLists,
  }) {
    activeList ??= this.activeList;
    if (activeList?.id == '') activeList = null;

    activeTask ??= this.activeTask;
    if (activeTask?.id == '') activeTask = null;

    return TasksState(
      activeList: activeList,
      activeTask: activeTask,
      loading: loading ?? this.loading,
      taskLists: taskLists ?? this.taskLists,
    );
  }
}
