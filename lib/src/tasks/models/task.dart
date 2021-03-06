import 'dart:convert';

import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final bool completed;

  final bool deleted;

  final String? description;

  final DateTime? dueDate;

  final String id;

  /// The ID of the task considered the parent, only if this task is nested.
  final String? parent;

  /// Title of the task.
  final String title;

  final DateTime updated;

  Task({
    this.completed = false,
    this.deleted = false,
    this.description,
    this.dueDate,
    this.id = '',
    this.parent,
    required this.title,
    DateTime? updated,
  }) : updated = updated ?? DateTime.now();

  @override
  List<Object?> get props {
    return [
      completed,
      deleted,
      description,
      dueDate,
      id,
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
      parent: map['parent'],
      title: map['title'] ?? '',
      updated: DateTime.fromMillisecondsSinceEpoch(map['updated']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));
}
