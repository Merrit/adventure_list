import 'package:adventure_list/src/tasks/tasks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

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

    group('serializing:', () {
      final task1 = Task(
        completed: false,
        deleted: false,
        description: null,
        dueDate: null,
        id: const Uuid().v4(),
        index: 0,
        parent: null,
        title: 'Take over the world!',
        updated: DateTime.now(),
      );

      final task2 = Task(
        completed: true,
        deleted: true,
        description: "Don't forget the quantum!!",
        dueDate: DateTime.now().add(const Duration(days: 1)),
        id: const Uuid().v4(),
        index: 1,
        parent: task1.id,
        title: 'Build mind control device',
        updated: DateTime.now().subtract(const Duration(hours: 4)),
      );

      final expectedTaskList = TaskList(
        id: const Uuid().v4(),
        index: 2,
        items: [task1, task2],
        title: 'Important Tasks',
      );

      test('fromMap() works', () {
        final map = {
          "id": expectedTaskList.id,
          "index": 2,
          "items": [
            {
              "completed": false,
              "deleted": false,
              "description": null,
              "dueDate": null,
              "id": task1.id,
              "index": 0,
              "parent": null,
              "title": "Take over the world!",
              "updated": task1.updated.millisecondsSinceEpoch
            },
            {
              "completed": true,
              "deleted": true,
              "description": "Don't forget the quantum!!",
              "dueDate": task2.dueDate?.millisecondsSinceEpoch,
              "id": task2.id,
              "index": 1,
              "parent": task1.id,
              "title": "Build mind control device",
              "updated": task2.updated.millisecondsSinceEpoch
            }
          ],
          "title": "Important Tasks"
        };
        expect(TaskList.fromMap(map), expectedTaskList);
      });

      test('fromJson() works', () {
        final json = '''{
          "id": "${expectedTaskList.id}",
          "index": 2,
          "items": [
            {
              "completed": false,
              "deleted": false,
              "description": null,
              "dueDate": null,
              "id": "${task1.id}",
              "index": 0,
              "parent": null,
              "title": "Take over the world!",
              "updated": ${task1.updated.millisecondsSinceEpoch}
            },
            {
              "completed": true,
              "deleted": true,
              "description": "Don't forget the quantum!!",
              "dueDate": ${task2.dueDate?.millisecondsSinceEpoch},
              "id": "${task2.id}",
              "index": 1,
              "parent": "${task1.id}",
              "title": "Build mind control device",
              "updated": ${task2.updated.millisecondsSinceEpoch}
            }
          ],
          "title": "Important Tasks"
        }''';

        expect(TaskList.fromJson(json), expectedTaskList);
      });
    });
  });
}
