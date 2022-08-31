import 'package:adventure_list/src/tasks/tasks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskListValidator:', () {
    test('tasks are sorted correctly', () {
      final recycleTask = Task(
        title: 'Take out recycling',
        id: UniqueKey().toString(),
        index: 2,
      );
      final garbageTask = Task(
        title: 'Take out garbage',
        id: UniqueKey().toString(),
        index: 0,
      );
      final playTask = Task(
        title: 'Play video games',
        id: UniqueKey().toString(),
        index: 1,
      );
      final vacuumTask = Task(
        title: 'Vacuum rug',
        id: UniqueKey().toString(),
        index: 0,
        completed: true,
        deleted: true,
      );
      final garbageSubTask1 = Task(
        title: 'Bathroom',
        id: UniqueKey().toString(),
        index: 1,
        parent: garbageTask.id,
      );
      final garbageSubTask2 = Task(
        title: 'Kitchen',
        id: UniqueKey().toString(),
        index: 0,
        parent: garbageTask.id,
      );
      final List<Task> unvalidatedTasks = [
        recycleTask,
        garbageSubTask2,
        vacuumTask,
        garbageSubTask1,
        garbageTask,
        playTask,
      ];
      final validatedTasks = TaskListValidator.tasksInOrder(unvalidatedTasks);
      expect(validatedTasks, [
        vacuumTask,
        garbageTask,
        playTask,
        recycleTask,
        garbageSubTask2,
        garbageSubTask1,
      ]);
    });
  });
}
