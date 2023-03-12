import 'dart:convert';

import 'package:adventure_list/src/tasks/tasks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('TaskList:', () {
    final taskListId = const Uuid().v4();

    final task1 = Task(
      completed: false,
      deleted: false,
      description: null,
      dueDate: null,
      id: const Uuid().v4(),
      index: 0,
      parent: null,
      taskListId: taskListId,
      title: 'task1',
      updated: DateTime.now(),
    );

    final task2 = Task(
      completed: false,
      deleted: false,
      description: null,
      dueDate: null,
      id: const Uuid().v4(),
      index: 1,
      parent: null,
      taskListId: taskListId,
      title: 'task2',
      updated: DateTime.now(),
    );

    final task3 = Task(
      completed: false,
      deleted: false,
      description: null,
      dueDate: null,
      id: const Uuid().v4(),
      index: 2,
      parent: null,
      taskListId: taskListId,
      title: 'task3',
      updated: DateTime.now(),
    );

    final task4 = Task(
      completed: false,
      deleted: false,
      description: null,
      dueDate: null,
      id: const Uuid().v4(),
      index: 3,
      parent: null,
      taskListId: taskListId,
      title: 'task4',
      updated: DateTime.now(),
    );

    final taskList = TaskList(
      id: taskListId,
      index: 0,
      items: [task1, task2, task3, task4],
      title: 'Important Tasks',
    );

    test('empty() works', () {
      final taskList = TaskList.empty();
      expect(taskList.id, '');
      expect(taskList.index, -1);
      expect(taskList.items, const []);
      expect(taskList.synced, false);
      expect(taskList.title, '');
    });

    test('reordering top-level tasks works', () {
      final updatedTaskList = taskList.reorderTasks(1, 3);
      expect(updatedTaskList.items[0].id, task1.id);
      expect(updatedTaskList.items[1].id, task3.id);
      expect(updatedTaskList.items[2].id, task4.id);
      expect(updatedTaskList.items[3].id, task2.id);
    });

    group('serializing:', () {
      final expectedTaskList = TaskList(
        id: const Uuid().v4(),
        index: 2,
        items: [task1, task2],
        synced: true,
        title: 'Important Tasks',
      );

      test('fromJson() works', () {
        final json = jsonEncode(expectedTaskList.toJson());
        expect(TaskList.fromJson(jsonDecode(json)), expectedTaskList);
      });
    });
  });
  group('List<TaskList>:', () {
    test('copy() works', () {
      final taskList1 = TaskList(
        id: 'id1',
        index: 0,
        items: const [],
        title: 'title1',
      );
      final taskList2 = TaskList(
        id: 'id2',
        index: 1,
        items: const [],
        title: 'title2',
      );
      final taskLists = [taskList1, taskList2];
      final copiedTaskLists = taskLists.copy();
      expect(copiedTaskLists, taskLists);
      expect(copiedTaskLists, isNot(same(taskLists)));
    });

    test('sorted() works', () {
      final taskList1 = TaskList(
        id: 'id1',
        index: 1,
        items: const [],
        title: 'title1',
      );
      final taskList2 = TaskList(
        id: 'id2',
        index: 0,
        items: const [],
        title: 'title2',
      );
      final taskLists = [taskList1, taskList2];
      final sortedTaskLists = taskLists.sorted();
      expect(sortedTaskLists[0], taskList2);
      expect(sortedTaskLists[1], taskList1);
    });
  });
}
