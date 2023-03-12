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
      deleted: false,
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
  });
}
