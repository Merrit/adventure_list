import 'package:equatable/equatable.dart';

import '../tasks.dart';

/// A Todo list.
///
/// Analogous to a `Calendar` object from the Google Calendar API.
class TaskList extends Equatable {
  /// Identifier of the calendar.
  final String id;

  final int index;

  final List<Task> items;

  final String title;

  const TaskList({
    required this.id,
    this.index = -1,
    required this.items,
    required this.title,
  });

  @override
  List<Object?> get props {
    return [
      id,
      index,
      items,
      title,
    ];
  }

  TaskList copyWith({
    String? description,
    String? id,
    int? index,
    List<Task>? items,
    String? title,
  }) {
    return TaskList(
      id: id ?? this.id,
      index: index ?? this.index,
      items: items ?? this.items,
      title: title ?? this.title,
    );
  }
}
