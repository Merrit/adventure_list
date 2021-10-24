import 'dart:developer';

import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

import '../../../domain/domain.dart';
import '../todo_repository.dart';

/// Use google calendars to sync Todo lists.
class GoogleTodoRepository implements TodoRepository {
  final CalendarApi _calendarApi;

  GoogleTodoRepository(
    auth.AuthClient _client,
  ) : _calendarApi = CalendarApi(_client);

  /// Every calendar with a descrition set as `todo_list` will be returned
  /// in the form on a `TodoList`.
  @override
  Future<List<TodoList>> getTodoLists() async {
    final todoLists = <TodoList>[];
    final calendarList = await _getCalendarsList();
    if (calendarList == null) {
      throw Exception('Unable to access user data.');
    }
    final calendars = calendarList.items!
        .where((calendar) => calendar.description == 'todo_list')
        .toList();
    await Future.forEach(calendars, (CalendarListEntry calendar) async {
      final todoList = calendar.toTodoList();
      final todos = await _getTodos(calendar.id!);
      todoList.todos.addAll(todos);
      todoLists.add(todoList);
    });
    return todoLists;
  }

  /// Returns metadata for all the user's calendars.
  Future<CalendarList?> _getCalendarsList() async {
    CalendarList? calendarList;
    try {
      calendarList = await _calendarApi.calendarList.list(
        minAccessRole: 'writer',
      );
    } on Exception catch (e) {
      log(
        'Error accessing user data: $e',
        name: 'google_todo_repository',
      );
      return null;
    }
    return calendarList;
  }

  /// Returns the Todos for the calendar with [id].
  Future<List<Todo>> _getTodos(String id) async {
    final events = await _calendarApi.events.list(id);
    final items = events.items;
    if (items == null) return <Todo>[];
    return items.map((Event event) => event.toTodo()).toList();
  }

  @override
  Future<TodoList?> createList(String name) async {
    Calendar? newCalendar;
    try {
      newCalendar = await _calendarApi.calendars.insert(
        Calendar(
          summary: name,
          // Add `todo_list` as a label so we know which calendars to load.
          // This is important because we don't want a user accidentally
          // messing up or deleting one of their regular calendars.
          description: 'todo_list',
        ),
      );
    } on ApiRequestError catch (e) {
      log(
        'Error creating calendar: $e',
        name: 'google_todo_repository',
      );
    }
    return newCalendar?.toTodoList();
  }

  @override
  Future<void> deleteList(TodoList list) async {
    await _calendarApi.calendars.delete(list.id);
  }

  final _defaultCalendarDate = EventDateTime(
    dateTime: DateTime(1970, 08, 30),
    timeZone: 'America/Toronto',
  );

  @override
  Future<Todo> createTodo({required TodoList list, required Todo todo}) async {
    final event = await _calendarApi.events.insert(
      Event(
        summary: todo.title,
        start: _defaultCalendarDate,
        end: _defaultCalendarDate,
      ),
      list.id,
    );
    return event.toTodo();
  }

  @override
  Future<void> deleteTodo({required TodoList list, required Todo todo}) async {
    return await _calendarApi.events.delete(list.id, todo.id);
  }

  @override
  Future<Todo> updateTodo({required TodoList list, required Todo todo}) async {
    final updatedEvent = await _calendarApi.events.update(
      Event(
        extendedProperties: EventExtendedProperties(
          shared: {
            'isComplete': '${todo.isComplete}',
          },
        ),
        iCalUID: todo.iCalUID,
        id: todo.id,
        start: _defaultCalendarDate,
        end: _defaultCalendarDate,
        summary: todo.title,
      ),
      list.id,
      todo.id,
    );
    return updatedEvent.toTodo();
  }
}

/* -------- Convenience extensions to convert to / from Todo formats. ------- */

extension on Calendar {
  TodoList toTodoList() {
    return TodoList(
      id: id ?? '',
      name: summary ?? '',
      source: TodoSource.google,
      todos: <Todo>[],
    );
  }
}

extension on CalendarListEntry {
  TodoList toTodoList() {
    return TodoList(
      id: id ?? '',
      name: summary ?? '',
      source: TodoSource.google,
      todos: <Todo>[],
    );
  }
}

extension on Event {
  Todo toTodo() {
    final isComplete =
        extendedProperties?.shared?['isComplete']?.toLowerCase() == 'true';
    return Todo(
      iCalUID: iCalUID!,
      id: id!,
      isComplete: isComplete,
      title: summary!,
    );
  }
}
