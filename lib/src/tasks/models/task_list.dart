import 'dart:convert';

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
    required this.index,
    required this.items,
    required this.title,
  });

  @override
  List<Object> get props => [id, index, items, title];

  TaskList copyWith({
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'index': index,
      'items': items.map((x) => x.toMap()).toList(),
      'title': title,
    };
  }

  factory TaskList.fromMap(Map<String, dynamic> map) {
    return TaskList(
      id: map['id'] ?? '',
      index: map['index'] ?? -1,
      items: map['items']?.map((x) => Task.fromMap(x)) ?? [],
      title: map['title'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory TaskList.fromJson(String source) =>
      TaskList.fromMap(json.decode(source));
}
