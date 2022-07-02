import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../tasks.dart';

/// A Todo list.
///
/// Analogous to a `Calendar` object from the Google Calendar API.
class TaskList extends Equatable {
  /// Identifier of the calendar.
  final String id;

  final List<Task> items;

  final TaskListDetails details;

  final String title;

  const TaskList({
    required this.id,
    required this.items,
    required this.details,
    required this.title,
  });

  @override
  List<Object> get props => [id, items, details, title];

  TaskList copyWith({
    String? id,
    List<Task>? items,
    TaskListDetails? details,
    String? title,
  }) {
    return TaskList(
      id: id ?? this.id,
      items: items ?? this.items,
      details: details ?? this.details,
      title: title ?? this.title,
    );
  }
}

class TaskListDetails extends Equatable {
  final int index;

  const TaskListDetails({
    this.index = -1,
  });

  @override
  List<Object> get props => [index];

  TaskListDetails copyWith({
    int? index,
  }) {
    return TaskListDetails(
      index: index ?? this.index,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'index': index,
    };
  }

  factory TaskListDetails.fromMap(Map<String, dynamic> map) {
    return TaskListDetails(
      index: map['index']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory TaskListDetails.fromJson(String source) =>
      TaskListDetails.fromMap(json.decode(source));
}
