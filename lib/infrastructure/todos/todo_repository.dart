import '../../domain/domain.dart';
import '../auth/src/google_auth_repository.dart';
import 'src/google_todo_repository.dart';

/// One Todo source to rule them all.
abstract class TodoRepository {
  /// Todos synced with Google Calendar.
  static Future<TodoRepository?> google(GoogleAuthRepository authRepo) async {
    final client = await authRepo.authenticatedClient();
    if (client == null) return null;
    return GoogleTodoRepository(client);
  }

  Future<TodoList?> createList(String name);

  Future<void> deleteList(TodoList list);

  Future<List<TodoList>> getTodoLists();

  Future<Todo> createTodo({required TodoList list, required Todo todo});

  Future<void> deleteTodo({required TodoList list, required Todo todo});

  Future<Todo> updateTodo({required TodoList list, required Todo todo});
}
