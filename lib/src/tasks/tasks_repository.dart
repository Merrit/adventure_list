import 'package:googleapis_auth/googleapis_auth.dart';

import '../authentication/authentication.dart';
import 'tasks.dart';

abstract class TasksRepository {
  static Future<TasksRepository> initialize({
    required ClientId clientId,
    required AccessCredentials credentials,
  }) async {
    return await GoogleCalendar.initialize(
      clientId: GoogleAuthIds.clientId,
      credentials: credentials,
    );
  }

  Future<List<TaskList>> getAll();

  Future<TaskList> createList({required String title});

  Future<Task> createTask({
    required String calendarId,
    required Task newTask,
  });

  Future<void> deleteList({required String id});

  Future<Task> updateTask({
    required String calendarId,
    required Task updatedTask,
  });
}
