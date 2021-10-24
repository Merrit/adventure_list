import '../domain.dart';

class TodoList {
  final String id;
  final String name;
  final TodoSource source;
  final List<Todo> todos;

  TodoList({
    required this.id,
    required this.name,
    required this.source,
    required this.todos,
  });

  TodoList copyWith({
    String? id,
    String? name,
    TodoSource? source,
    List<Todo>? todos,
  }) {
    return TodoList(
      id: id ?? this.id,
      name: name ?? this.name,
      source: source ?? this.source,
      todos: todos ?? this.todos,
    );
  }
}
