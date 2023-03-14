import 'dart:convert';

import 'package:adventure_list/src/tasks/tasks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
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

  group('TaskList:', () {
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
    final taskList1 = TaskList(
      id: 'test-tasklist-id-1',
      index: 0,
      items: const [],
      title: 'Test TaskList 1',
    );

    final taskList2 = TaskList(
      id: 'test-tasklist-id-2',
      index: 1,
      items: const [],
      title: 'Test TaskList 2',
    );

    final taskList3 = TaskList(
      id: 'test-tasklist-id-3',
      index: 2,
      items: const [],
      title: 'Test TaskList 3',
    );

    final taskList4 = TaskList(
      id: 'test-tasklist-id-4',
      index: 3,
      items: const [],
      title: 'Test TaskList 4',
    );

    test('copy() works', () {
      final taskLists = [taskList1, taskList2];
      final copiedTaskLists = taskLists.copy();
      expect(copiedTaskLists, taskLists);
    });

    test('getTaskListById() works', () {
      final taskLists = [taskList1, taskList2];
      expect(taskLists.getTaskListById(taskList1.id), taskList1);
      expect(taskLists.getTaskListById(taskList2.id), taskList2);
      expect(taskLists.getTaskListById(taskList3.id), null);
    });

    test('getTaskById() works', () {
      final taskList1WithTasks = taskList1.copyWith(
        items: [task1, task2, task3, task4],
      );

      final taskLists = [taskList1WithTasks, taskList2];
      expect(taskLists.getTaskById(task1.id), task1);
      expect(taskLists.getTaskById(task2.id), task2);
      expect(taskLists.getTaskById(task3.id), task3);
      expect(taskLists.getTaskById(task4.id), task4);
      expect(taskLists.getTaskById('task-20'), null);
    });

    test('sorted() works', () {
      final taskLists = [taskList4, taskList2, taskList3, taskList1];
      final sortedTaskLists = taskLists.sorted();
      expect(sortedTaskLists[0].id, taskList1.id);
      expect(sortedTaskLists[1].id, taskList2.id);
      expect(sortedTaskLists[2].id, taskList3.id);
      expect(sortedTaskLists[3].id, taskList4.id);
    });

    test('addTaskList() works', () {
      final taskLists = [taskList1, taskList2];
      final newTaskList = taskList3.copyWith(index: 0);
      final updatedTaskLists = taskLists.addTaskList(newTaskList);
      expect(updatedTaskLists[0], taskList1);
      expect(updatedTaskLists[1], taskList2);
      expect(updatedTaskLists[2].id, taskList3.id);
      expect(updatedTaskLists[2].index, 2);
    });

    test('reorderTaskLists() works', () {
      final taskLists = [taskList1, taskList2, taskList3];
      final updatedTaskLists = taskLists.reorderTaskLists(taskList1, 2);
      expect(updatedTaskLists[0].id, taskList2.id);
      expect(updatedTaskLists[1].id, taskList3.id);
      expect(updatedTaskLists[2].id, taskList1.id);
    });

    test('removeTaskList() works', () {
      final taskLists = [taskList1, taskList2, taskList3];
      final updatedTaskLists = taskLists.removeTaskList(taskList2);
      expect(updatedTaskLists.length, 2);
      final firstTaskList = updatedTaskLists[0];
      expect(firstTaskList.id, taskList1.id);
      expect(firstTaskList.index, 0);
      final secondTaskList = updatedTaskLists[1];
      expect(secondTaskList.id, taskList3.id);
      expect(secondTaskList.index, 1);
    });

    test('updateTaskList() works', () {
      final taskLists = [taskList1, taskList2, taskList3];
      final updatedTaskList = taskList2.copyWith(title: 'Updated Title');
      final updatedTaskLists = taskLists.updateTaskList(updatedTaskList);
      expect(updatedTaskLists.length, 3);
      expect(updatedTaskLists[0], taskList1);
      final secondTaskList = updatedTaskLists[1];
      expect(secondTaskList.id, taskList2.id);
      expect(secondTaskList.index, 1);
      expect(secondTaskList.title, 'Updated Title');
      expect(updatedTaskLists[2], taskList3);
    });

    test('addTask() works', () {
      final taskList1WithTasks = taskList1.copyWith(
        items: [task1, task2, task3, task4],
      );
      final taskLists = [taskList1WithTasks, taskList2];
      final newTask = Task(
        id: const Uuid().v4(),
        index: 0,
        taskListId: taskList1.id,
        title: 'New Task',
      );
      final updatedTaskLists = taskLists.addTask(newTask);
      expect(updatedTaskLists.length, 2);
      final firstTaskList = updatedTaskLists[0];
      expect(firstTaskList.id, taskList1.id);
      expect(firstTaskList.index, 0);
      expect(firstTaskList.items.length, 5);
      expect(firstTaskList.items[0], task1);
      expect(firstTaskList.items[1], task2);
      expect(firstTaskList.items[2], task3);
      expect(firstTaskList.items[3], task4);
      expect(firstTaskList.items[4].id, newTask.id);
      expect(firstTaskList.items[4].index, 4);
      expect(firstTaskList.items[4].title, 'New Task');
      expect(updatedTaskLists[1], taskList2);
    });

    test('removeTask() works', () {
      final taskList1WithTasks = taskList1.copyWith(
        id: taskListId,
        items: [task1, task2, task3, task4],
      );
      final taskLists = [taskList1WithTasks, taskList2];
      final updatedTaskLists = taskLists.removeTask(task3);
      expect(updatedTaskLists.length, 2);
      final firstTaskList = updatedTaskLists[0];
      expect(firstTaskList.id, taskList1WithTasks.id);
      expect(firstTaskList.index, 0);
      expect(firstTaskList.items.length, 3);
      expect(firstTaskList.items[0], task1);
      expect(firstTaskList.items[1], task2);
      expect(firstTaskList.items[2].id, task4.id);
      expect(firstTaskList.items[2].index, 2);
      expect(updatedTaskLists[1], taskList2);
    });

    test('updateTask() works', () {
      final taskList1WithTasks = taskList1.copyWith(
        id: taskListId,
        items: [task1, task2, task3, task4],
      );
      final taskLists = [taskList1WithTasks, taskList2];
      final updatedTask = task3.copyWith(title: 'Updated Title');
      final updatedTaskLists = taskLists.updateTask(updatedTask);
      expect(updatedTaskLists.length, 2);
      final firstTaskList = updatedTaskLists[0];
      expect(firstTaskList.id, taskList1WithTasks.id);
      expect(firstTaskList.index, 0);
      expect(firstTaskList.items.length, 4);
      expect(firstTaskList.items[0], task1);
      expect(firstTaskList.items[1], task2);
      expect(firstTaskList.items[2].id, updatedTask.id);
      expect(firstTaskList.items[2].index, 2);
      expect(firstTaskList.items[2].title, 'Updated Title');
      expect(firstTaskList.items[3], task4);
      expect(updatedTaskLists[1], taskList2);
    });

    test('reorderTask() works', () {
      final taskList1WithTasks = taskList1.copyWith(
        id: taskListId,
        items: [task1, task2, task3, task4],
      );
      final taskLists = [taskList1WithTasks, taskList2];
      final updatedTaskLists = taskLists.reorderTask(task1, 3);
      expect(updatedTaskLists.length, 2);
      final firstTaskList = updatedTaskLists[0];
      expect(firstTaskList.id, taskList1WithTasks.id);
      expect(firstTaskList.index, 0);
      expect(firstTaskList.items.length, 4);
      expect(firstTaskList.items[0].id, task2.id);
      expect(firstTaskList.items[0].index, 0);
      expect(firstTaskList.items[1].id, task3.id);
      expect(firstTaskList.items[1].index, 1);
      expect(firstTaskList.items[2].id, task4.id);
      expect(firstTaskList.items[2].index, 2);
      expect(firstTaskList.items[3].id, task1.id);
      expect(firstTaskList.items[3].index, 3);
      expect(updatedTaskLists[1], taskList2);
    });
  });
}
