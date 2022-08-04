import 'package:googleapis_auth/googleapis_auth.dart';

import '../authentication/authentication.dart';
import 'tasks.dart';

/// Abstract interface for task repositories.
///
/// Currently supports [GoogleCalendar].
///
/// Support for a local-only repository is being considered.
abstract class TasksRepository {
  // TODO: Genericize this initializer for non-calendar.
  // Maybe just have the initializer in the concrete classes.
  static Future<TasksRepository> initialize({
    required ClientId clientId,
    required AccessCredentials credentials,
  }) async {
    return await GoogleCalendar.initialize(
      clientId: GoogleAuthIds.clientId,
      credentials: credentials,
    );
  }

  /// Fetch all of the user's [TaskList]s.
  Future<List<TaskList>> getAll();

  /// Create a new [TaskList].
  Future<TaskList> createList({required String title});

  /// Delete the [TaskList] with [id].
  Future<void> deleteList({required String id});

  /// Update the provided [TaskList] in the repository.
  Future<void> updateList({required TaskList list});

  /// Create a new [Task].
  Future<Task> createTask({
    required String calendarId, // TODO: Genericize this for non-calendar.
    required Task newTask,
  });

  /// Update the provided [Task] in the repository.
  Future<Task> updateTask({
    required String calendarId, // TODO: Genericize this for non-calendar.
    required Task updatedTask,
  });
}
