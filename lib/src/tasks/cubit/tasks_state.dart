part of 'tasks_cubit.dart';

class TasksState extends Equatable {
  final TaskList? activeList;
  final bool loading;
  final List<TaskList> taskLists;

  const TasksState({
    this.activeList,
    required this.loading,
    required this.taskLists,
  });

  @override
  List<Object?> get props => [activeList, loading, taskLists];

  TasksState copyWith({
    TaskList? activeList,
    bool? loading,
    List<TaskList>? taskLists,
  }) {
    return TasksState(
      activeList: activeList ?? this.activeList,
      loading: loading ?? this.loading,
      taskLists: taskLists ?? this.taskLists,
    );
  }
}
