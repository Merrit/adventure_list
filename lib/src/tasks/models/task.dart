import 'dart:convert';

import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final bool completed;

  final bool deleted;

  final String? description;

  final DateTime? dueDate;

  final String id;

  final int index;

  /// The ID of the task considered the parent, only if this task is nested.
  final String? parent;

  /// Title of the task.
  final String title;

  final DateTime updated;

  const Task._({
    required this.completed,
    required this.deleted,
    required this.description,
    required this.dueDate,
    required this.id,
    required this.index,
    required this.parent,
    required this.title,
    required this.updated,
  });

  factory Task({
    bool completed = false,
    bool deleted = false,
    String? description,
    DateTime? dueDate,
    String id = '',
    int index = -1,
    String? parent,
    required String title,
    DateTime? updated,
  }) {
    if (dueDate != null) {
      // Remove microseconds so serialization will work reliably.
      dueDate = DateTime.fromMillisecondsSinceEpoch(
        dueDate.millisecondsSinceEpoch,
      );
    }

    if (parent == '') parent = null;

    updated ??= DateTime.now();
    // Remove microseconds so serialization will work reliably.
    updated = DateTime.fromMillisecondsSinceEpoch(
      updated.millisecondsSinceEpoch,
    );

    return Task._(
      completed: completed,
      deleted: deleted,
      description: description,
      dueDate: dueDate,
      id: id,
      index: index,
      parent: parent,
      title: title,
      updated: updated,
    );
  }

  @override
  List<Object?> get props {
    return [
      completed,
      deleted,
      description,
      dueDate,
      id,
      index,
      parent,
      title,
      updated,
    ];
  }

  Task copyWith({
    bool? completed,
    bool? deleted,
    String? description,
    DateTime? dueDate,
    String? id,
    int? index,
    String? parent,
    String? title,
    DateTime? updated,
  }) {
    return Task(
      completed: completed ?? this.completed,
      deleted: deleted ?? this.deleted,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      id: id ?? this.id,
      index: index ?? this.index,
      parent: parent ?? this.parent,
      title: title ?? this.title,
      updated: updated ?? this.updated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completed': completed,
      'deleted': deleted,
      'description': description,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'id': id,
      'index': index,
      'parent': parent,
      'title': title,
      'updated': updated.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      completed: map['completed'] ?? false,
      deleted: map['deleted'] ?? false,
      description: map['description'],
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
          : null,
      id: map['id'] ?? '',
      index: map['index'] ?? -1,
      parent: map['parent'],
      title: map['title'] ?? '',
      updated: DateTime.fromMillisecondsSinceEpoch(map['updated']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));
}
