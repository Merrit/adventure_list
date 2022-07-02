import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final bool completed;

  final bool deleted;

  final String? description;

  final DateTime? dueDate;

  final String id;

  // final String? parent;

  /// Title of the task.
  final String title;

  final DateTime updated;

  Task({
    this.completed = false,
    this.deleted = false,
    this.description,
    this.dueDate,
    this.id = '',
    // required this.parent,
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
      // parent,
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
      // parent: parent ?? this.parent,
      title: title ?? this.title,
      updated: updated ?? this.updated,
    );
  }
}
