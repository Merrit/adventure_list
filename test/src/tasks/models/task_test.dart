import 'dart:convert';

import 'package:adventure_list/src/tasks/tasks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('Task:', () {
    final int dueDate = DateTime //
            .now()
        .add(const Duration(days: 2))
        .millisecondsSinceEpoch;
    final String id = const Uuid().v4();
    final int updated = DateTime.now().millisecondsSinceEpoch;

    final expectedTask = Task(
      completed: true,
      description: 'Gotta look good!',
      dueDate: DateTime.fromMillisecondsSinceEpoch(dueDate),
      id: id,
      index: 3,
      parent: null,
      taskListId: 'test-task-list-id',
      title: 'Make promo video',
      updated: DateTime.fromMillisecondsSinceEpoch(updated),
    );

    final json = jsonEncode(expectedTask.toJson());

    test('fromJson() works', () {
      expect(Task.fromJson(jsonDecode(json)), expectedTask);
    });

    test('toJson() works', () {
      expect(Task.fromJson(jsonDecode(json)).toJson(), expectedTask.toJson());
    });

    test('empty() works', () {
      expect(Task.empty(), isA<Task>());
    });

    test('copyWith() works', () {
      final updatedTask = expectedTask.copyWith(description: 'Firefox!');
      expect(updatedTask, isA<Task>());
      expect(updatedTask.description, 'Firefox!');
      expect(updatedTask.id, id);
    });
  });

  group('ListOfTasksExtensions:', () {
    const testTaskListId = 'test-task-list-id';

    final task1 = Task(
      id: 'test-task-id-1',
      index: 0,
      taskListId: testTaskListId,
      title: 'Test Task 1',
    );

    final task2 = Task(
      id: 'test-task-id-2',
      index: 1,
      taskListId: testTaskListId,
      title: 'Test Task 2',
    );

    final task3 = Task(
      id: 'test-task-id-3',
      index: 2,
      taskListId: testTaskListId,
      title: 'Test Task 3',
    );

    final subTask1 = Task(
      id: 'subtask1',
      taskListId: testTaskListId,
      title: 'Test Subtask 1',
      parent: task1.id,
    );

    final subTask2 = Task(
      id: 'subtask2',
      taskListId: testTaskListId,
      title: 'Test Subtask 2',
      parent: task1.id,
    );

    final subTask3 = Task(
      id: 'subtask3',
      taskListId: testTaskListId,
      title: 'Test Subtask 3',
      parent: task2.id,
    );

    test('addTask() works', () {
      List<Task> tasks = <Task>[].addTask(task1);
      expect(tasks, isA<List<Task>>());
      expect(tasks.length, 1);
      expect(tasks.first, task1);
      tasks = tasks.addTask(task2);
      expect(tasks.length, 2);
      expect(tasks.first, task1);
      expect(tasks.last, task2);
    });

    test('copy() works', () {
      final tasks = <Task>[task1, task2];
      final copiedTasks = tasks.copy();
      expect(copiedTasks, isA<List<Task>>());
      expect(copiedTasks.length, 2);
      expect(copiedTasks.first, task1);
      expect(copiedTasks.last, task2);
    });

    test('completedTasks() works', () {
      final tasks = <Task>[task1, task2, task3];
      final completedTasks = tasks.completedTasks();
      expect(completedTasks, isA<List<Task>>());
      expect(completedTasks.length, 0);
      final updatedTasks = tasks
          .map((t) => t.copyWith(completed: t.title == 'Test Task 2'))
          .toList();
      final updatedCompletedTasks = updatedTasks.completedTasks();
      expect(updatedCompletedTasks.length, 1);
      expect(updatedCompletedTasks.first.title, 'Test Task 2');
      expect(updatedCompletedTasks.first.completed, true);
    });

    test('incompleteTasks() works', () {
      final tasks = <Task>[task1, task2, task3];
      final incompleteTasks = tasks.incompleteTasks();
      expect(incompleteTasks, isA<List<Task>>());
      expect(incompleteTasks.length, 3);
      final updatedTasks = tasks
          .map((t) => t.copyWith(completed: t.title == 'Test Task 2'))
          .toList();
      final updatedIncompleteTasks = updatedTasks.incompleteTasks();
      expect(updatedIncompleteTasks.length, 2);
      expect(updatedIncompleteTasks.first.title, 'Test Task 1');
      expect(updatedIncompleteTasks.first.completed, false);
      expect(updatedIncompleteTasks.last.title, 'Test Task 3');
      expect(updatedIncompleteTasks.last.completed, false);
    });

    test('getTaskById() works', () {
      final tasks = <Task>[task1, task2, task3];
      final task = tasks.getTaskById(task2.id);
      expect(task, isA<Task>());
      expect(task, task2);
    });

    test('markTaskCompleted() works', () {
      final tasks = <Task>[task1, task2, task3];
      final updatedTasks = tasks.markTaskCompleted(task2);
      expect(updatedTasks, isA<List<Task>>());
      expect(updatedTasks.length, 3);
      expect(updatedTasks.first, task1);
      expect(updatedTasks[1].title, 'Test Task 2');
      expect(updatedTasks[1].completed, true);
      expect(updatedTasks.last, task3);
    });

    test('markTaskNotCompleted() works', () {
      final tasks = <Task>[task1, task2, task3];
      final updatedTasks = tasks.markTaskNotCompleted(task2);
      expect(updatedTasks, isA<List<Task>>());
      expect(updatedTasks.length, 3);
      expect(updatedTasks.first, task1);
      expect(updatedTasks[1].title, 'Test Task 2');
      expect(updatedTasks[1].completed, false);
      expect(updatedTasks.last, task3);
    });

    test('reorderTasks() works', () {
      final tasks = <Task>[task1, task2, task3];
      final updatedTasks = tasks.reorderTasks(task1, 2);
      expect(updatedTasks, isA<List<Task>>());
      expect(updatedTasks.length, 3);
      expect(updatedTasks[0].title, 'Test Task 2');
      expect(updatedTasks[0].index, 0);
      expect(updatedTasks[1].title, 'Test Task 3');
      expect(updatedTasks[1].index, 1);
      expect(updatedTasks[2].title, 'Test Task 1');
      expect(updatedTasks[2].index, 2);
    });

    test('removeTask() works', () {
      final tasks = <Task>[task1, task2, task3];
      final updatedTasks = tasks.removeTask(task2);
      expect(updatedTasks, isA<List<Task>>());
      expect(updatedTasks.length, 2);
      expect(updatedTasks.first, task1);
      expect(updatedTasks.last.title, 'Test Task 3');
      expect(updatedTasks.last.index, 1);
    });

    test('removeTask() on parent also removes subtasks', () {
      final tasks = <Task>[task1, task2, task3, subTask1, subTask2, subTask3];
      final updatedTasks = tasks.removeTask(task2);
      expect(updatedTasks, isA<List<Task>>());
      expect(updatedTasks.length, 4);
      expect(updatedTasks.first, task1);
      expect(updatedTasks[1].title, 'Test Task 3');
      expect(updatedTasks[1].index, 1);
      expect(updatedTasks[2].title, 'Test Subtask 1');
      expect(updatedTasks[2].index, 0);
      expect(updatedTasks[3].title, 'Test Subtask 2');
      expect(updatedTasks[3].index, 1);
    });

    test('removeTasks() works', () {
      final tasks = <Task>[task1, task2, task3, subTask1, subTask2, subTask3];
      final updatedTasks = tasks.removeTasks([task2, subTask1]);
      expect(updatedTasks.length, 3);
      expect(updatedTasks.first, task1);
      expect(updatedTasks[1].title, 'Test Task 3');
      expect(updatedTasks[1].index, 1);
      expect(updatedTasks.last.title, 'Test Subtask 2');
      expect(updatedTasks.last.index, 0);
    });

    test('sortedByDueDate() works', () {
      final task1WithDueDate = task1.copyWith(
        dueDate: DateTime.now().add(const Duration(days: 2)),
      );
      final task2WithDueDate = task2.copyWith(
        dueDate: DateTime.now().add(const Duration(days: 3)),
      );
      final task3WithDueDate = task3.copyWith(
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );
      final tasks = <Task>[
        task1WithDueDate,
        task2WithDueDate,
        task3WithDueDate,
      ];
      final sortedTasks = tasks.sortedByDueDate();
      expect(sortedTasks, isA<List<Task>>());
      expect(sortedTasks.length, 3);
      expect(sortedTasks.first, task3WithDueDate);
      expect(sortedTasks[1], task1WithDueDate);
      expect(sortedTasks.last, task2WithDueDate);
    });

    test('sortedByIndex() works', () {
      final updatedTask1 = task1.copyWith(index: 2);
      final updatedTask2 = task2.copyWith(index: 3);
      final updatedTask3 = task3.copyWith(index: 1);
      final tasks = <Task>[updatedTask1, updatedTask2, updatedTask3];
      final sortedTasks = tasks.sortedByIndex();
      expect(sortedTasks, isA<List<Task>>());
      expect(sortedTasks.length, 3);
      expect(sortedTasks.first, updatedTask3);
      expect(sortedTasks[1], updatedTask1);
      expect(sortedTasks.last, updatedTask2);
    });

    test('sortedByTitle() works', () {
      final tasks = <Task>[task3, task1, task2];
      final sortedTasks = tasks.sortedByTitle();
      expect(sortedTasks, isA<List<Task>>());
      expect(sortedTasks.length, 3);
      expect(sortedTasks.first, task1);
      expect(sortedTasks[1], task2);
      expect(sortedTasks.last, task3);
    });

    test('sortedByUpdated() works', () {
      final task1WithUpdated = task1.copyWith(
        updated: DateTime.now().subtract(const Duration(days: 2)),
      );
      final task2WithUpdated = task2.copyWith(
        updated: DateTime.now().subtract(const Duration(days: 3)),
      );
      final task3WithUpdated = task3.copyWith(
        updated: DateTime.now().subtract(const Duration(days: 1)),
      );
      final tasks = <Task>[
        task1WithUpdated,
        task2WithUpdated,
        task3WithUpdated,
      ];
      final sortedTasks = tasks.sortedByUpdated();
      expect(sortedTasks, isA<List<Task>>());
      expect(sortedTasks.length, 3);
      expect(sortedTasks.first, task3WithUpdated);
      expect(sortedTasks[1], task1WithUpdated);
      expect(sortedTasks.last, task2WithUpdated);
    });

    test('subtasksOf() works', () {
      final tasks = <Task>[task1, task2, task3, subTask1, subTask2, subTask3];
      final task1Subtasks = tasks.subtasksOf(task1.id);
      expect(task1Subtasks, isA<List<Task>>());
      expect(task1Subtasks.length, 2);
      expect(task1Subtasks.first, subTask1);
      expect(task1Subtasks.last, subTask2);
      final task2Subtasks = tasks.subtasksOf(task2.id);
      expect(task2Subtasks, isA<List<Task>>());
      expect(task2Subtasks.length, 1);
      expect(task2Subtasks.first, subTask3);
      final task3Subtasks = tasks.subtasksOf(task3.id);
      expect(task3Subtasks, isA<List<Task>>());
      expect(task3Subtasks.length, 0);
    });

    test('topLevelTasks() works', () {
      final tasks = <Task>[task1, task2, task3, subTask1, subTask2, subTask3];
      final topLevelTasks = tasks.topLevelTasks();
      expect(topLevelTasks, isA<List<Task>>());
      expect(topLevelTasks.length, 3);
      expect(topLevelTasks.first, task1);
      expect(topLevelTasks[1], task2);
      expect(topLevelTasks.last, task3);
    });

    test('updateIndexes() works', () {
      final tasks = <Task>[
        task1.copyWith(index: 2),
        task2.copyWith(index: 3),
        task3.copyWith(index: 6),
        subTask1.copyWith(index: 4),
        subTask2.copyWith(index: 5),
        subTask3.copyWith(index: 1),
      ];
      final updatedTasks = tasks.updateIndexes();
      expect(updatedTasks, isA<List<Task>>());
      expect(updatedTasks.length, 6);
      expect(updatedTasks.first.index, 0);
      expect(updatedTasks.first.title, 'Test Task 1');
      expect(updatedTasks[1].index, 1);
      expect(updatedTasks[1].title, 'Test Task 2');
      expect(updatedTasks[2].index, 2);
      expect(updatedTasks[2].title, 'Test Task 3');
      expect(updatedTasks[3].index, 0);
      expect(updatedTasks[3].title, 'Test Subtask 1');
      expect(updatedTasks[4].index, 1);
      expect(updatedTasks[4].title, 'Test Subtask 2');
      expect(updatedTasks.last.index, 0);
      expect(updatedTasks.last.title, 'Test Subtask 3');
    });

    test('updateTask() works', () {
      final tasks = <Task>[task1, task2, task3];
      final updatedTask = task2.copyWith(title: 'Updated Task 2');
      final updatedTasks = tasks.updateTask(updatedTask);
      expect(updatedTasks, isA<List<Task>>());
      expect(updatedTasks.length, 3);
      expect(updatedTasks.first, task1);
      expect(updatedTasks[1].title, 'Updated Task 2');
      expect(updatedTasks.last, task3);
    });
  });
}
