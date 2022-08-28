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

  final List<Task> subTasks;

  /// Title of the task.
  final String title;

  final DateTime updated;

  Task({
    this.completed = false,
    this.deleted = false,
    this.description,
    this.dueDate,
    this.id = '',
    this.index = -1,
    this.parent,
    this.subTasks = const [],
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
      index,
      parent,
      subTasks,
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
    List<Task>? subTasks,
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
      subTasks: subTasks ?? this.subTasks,
      title: title ?? this.title,
      updated: updated ?? this.updated,
    );
  }

  Task addSubTask(Task newSubTask) {
    return copyWith(
      subTasks: [...subTasks, newSubTask],
    );
  }

  Task clearAllSubTasks() {
    final subTasks = List<Task>.from(this.subTasks);
    for (var i = 0; i < subTasks.length; i++) {
      final updatedSubTask = subTasks[i].copyWith(
        completed: true,
        deleted: true,
      );
      subTasks.removeAt(i);
      subTasks.insert(i, updatedSubTask);
    }
    return copyWith(subTasks: subTasks);
  }

  Task clearCompletedSubTasks() {
    final subTasks = List<Task>.from(this.subTasks);
    for (var i = 0; i < subTasks.length; i++) {
      if (subTasks[i].completed) {
        final updatedSubTask = subTasks[i].copyWith(deleted: true);
        subTasks.removeAt(i);
        subTasks.insert(i, updatedSubTask);
      }
    }
    return copyWith(subTasks: subTasks);
  }

  /// Updates the sub-task that matches the id of the provided task.
  ///
  /// Returns the updated parent task with updated sub-task.
  Task updateSubTask(Task updatedSubTask) {
    final subTasks = List<Task>.from(this.subTasks)
      ..removeWhere((element) => element.id == updatedSubTask.id)
      ..add(updatedSubTask)
      ..sort((a, b) => a.index.compareTo(b.index));

    return copyWith(subTasks: subTasks);
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
