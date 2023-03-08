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
    final Map<String, dynamic> taskMap = {
      'completed': true,
      'deleted': false,
      'description': 'Gotta look good!',
      'dueDate': dueDate,
      'id': id,
      'index': 3,
      'parent': null,
      'title': 'Make promo video',
      'updated': updated,
    };
    final String json = jsonEncode(taskMap);
    final expectedTask = Task(
      completed: true,
      deleted: false,
      description: 'Gotta look good!',
      dueDate: DateTime.fromMillisecondsSinceEpoch(dueDate),
      id: id,
      index: 3,
      parent: null,
      title: 'Make promo video',
      updated: DateTime.fromMillisecondsSinceEpoch(updated),
    );

    test('fromJson() works', () {
      expect(Task.fromJson(jsonDecode(json)), expectedTask);
    });
  });
}
