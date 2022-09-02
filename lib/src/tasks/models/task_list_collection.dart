import 'models.dart';

/// TODO: Refactor TaskCubit's `taskLists` to being this class with helper
/// methods and etc.
class TaskListCollection {
  final List<TaskList> allTaskLists;

  const TaskListCollection._({
    required this.allTaskLists,
  });

  factory TaskListCollection(List<TaskList> allTaskLists) {
    allTaskLists.sort((a, b) => a.index.compareTo(b.index));

    return TaskListCollection._(
      allTaskLists: allTaskLists,
    );
  }
}
