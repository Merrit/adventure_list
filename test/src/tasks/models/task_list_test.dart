import 'package:adventure_list/src/tasks/tasks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskList:', () {
    test('reordering top-level tasks works', () {
      final tasks = <Task>[
        Task(title: 'task0', index: 0),
        Task(title: 'task1', index: 1),
        Task(title: 'task2', index: 2),
        Task(title: 'task3', index: 3),
      ];
      final taskList = TaskList(
        id: 'id',
        index: 0,
        items: tasks,
        title: 'title',
      );
      final updatedTaskList = taskList.reorderTasks(1, 3);
      expect(updatedTaskList.items[0], tasks[0]);
      expect(updatedTaskList.items[1], tasks[2].copyWith(index: 1));
      expect(updatedTaskList.items[2], tasks[3].copyWith(index: 2));
      expect(updatedTaskList.items[3], tasks[1].copyWith(index: 3));
    });
  });
}
