import 'package:adventure_list/src/authentication/authentication.dart';
import 'package:adventure_list/src/logs/logs.dart';
import 'package:adventure_list/src/storage/storage_service.dart';
import 'package:adventure_list/src/tasks/tasks.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthenticationCubit extends MockCubit<AuthenticationState>
    implements AuthenticationCubit {}

class MockStorageService extends Mock implements StorageService {}

class MockTasksRepository extends Mock implements TasksRepository {}

class FakeTaskList extends Fake implements TaskList {}

class FakeTask extends Fake implements Task {}

late MockAuthenticationCubit _authCubit;
late MockStorageService _storageService;
late MockTasksRepository _tasksRepository;

late TasksCubit _tasksCubit;

TasksState get state => _tasksCubit.state;

final AccessToken defaultAccessToken = AccessToken(
  '',
  '',
  DateTime.now().toUtc(),
);

final AuthenticationState defaultAuthState = AuthenticationState(
  accessCredentials: AccessCredentials(
    defaultAccessToken,
    null,
    [],
  ),
  signedIn: true,
);

void main() {
  setUpAll(() async {
    /* ----------------------------- StorageService ----------------------------- */
    _storageService = MockStorageService();

    when(() => _storageService.getStorageAreaValues(any())).thenAnswer(
      (_) async => [],
    );

    when(() => _storageService.getValue(
          any(),
          storageArea: any(named: 'storageArea'),
        )).thenAnswer((_) async => null);

    when(() => _storageService.saveStorageAreaValues(
          storageArea: any(named: 'storageArea'),
          entries: any(named: 'entries'),
        )).thenAnswer((_) async {});

    when(() => _storageService.saveValue(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((_) async {});

    await initializeLogger(_storageService);

    registerFallbackValue(FakeTaskList());
    registerFallbackValue(FakeTask());
  });

  group('TasksCubit:', () {
    setUp(() async {
      /* -------------------------------- AuthCubit ------------------------------- */
      _authCubit = MockAuthenticationCubit();

      when(() => _authCubit.state).thenReturn(defaultAuthState);

      /* ----------------------------- TasksRepository ---------------------------- */
      _tasksRepository = MockTasksRepository();

      when(() => _tasksRepository.getAll()).thenAnswer((_) async => []);

      when(() => _tasksRepository.createList(title: any(named: 'title')))
          .thenAnswer((invokation) async => TaskList(
                id: UniqueKey().toString(),
                index: 0,
                items: const [],
                title:
                    invokation.namedArguments[const Symbol('title')] as String,
              ));

      when(() => _tasksRepository.deleteList(id: any(named: 'id')))
          .thenAnswer((_) async {});

      when(() => _tasksRepository.updateList(list: any(named: 'list')))
          .thenAnswer((_) async {});

      when(() => _tasksRepository.createTask(
            newTask: any(named: 'newTask'),
            taskListId: any(named: 'taskListId'),
          )).thenAnswer((invokation) async {
        final providedTask =
            invokation.namedArguments[const Symbol('newTask')] as Task;
        return providedTask.copyWith(
          id: UniqueKey().toString(),
        );
      });

      when(() => _tasksRepository.updateTask(
            taskListId: any(named: 'taskListId'),
            updatedTask: any(named: 'updatedTask'),
          )).thenAnswer((invokation) async {
        final providedTask =
            invokation.namedArguments[const Symbol('updatedTask')] as Task;
        return providedTask;
      });

      /* ------------------------------- TasksCubit ------------------------------- */

      _tasksCubit = TasksCubit(
        _authCubit,
        _storageService,
        tasksRepository: _tasksRepository,
      );
    });

    test('clearing completed tasks works', () async {
      // Prepare state with tasks.
      await _tasksCubit.createList('Test List');
      _tasksCubit.setActiveList(state.taskLists.first.id);
      final task1 = await _tasksCubit.createTask(
        Task(title: 'Test Task 1'),
      );
      final task2 = await _tasksCubit.createTask(
        Task(title: 'Test Task 2'),
      );
      final task3 = await _tasksCubit.createTask(
        Task(title: 'Test Task 3'),
      );
      final taskWithSubTasks = await _tasksCubit.createTask(
        Task(title: 'Test Task with sub-tasks'),
      );
      final subTask1 = await _tasksCubit.createTask(
        Task(title: 'Sub-task 1', parent: taskWithSubTasks.id),
      );
      final subTask2 = await _tasksCubit.createTask(
        Task(title: 'Sub-task 2', parent: taskWithSubTasks.id),
      );
      final subTask3 = await _tasksCubit.createTask(
        Task(title: 'Sub-task 3', parent: taskWithSubTasks.id),
      );
      expect(state.activeList?.items, [
        task1,
        task2,
        task3,
        taskWithSubTasks,
        subTask1,
        subTask2,
        subTask3,
      ]);

      // Set a top-level task and a sub-task as completed.
      await _tasksCubit.updateTask(task1.copyWith(completed: true));
      await _tasksCubit.updateTask(subTask1.copyWith(completed: true));
      expect(state.activeList?.items, [
        task1.copyWith(completed: true),
        task2,
        task3,
        taskWithSubTasks,
        subTask1.copyWith(completed: true),
        subTask2,
        subTask3,
      ]);

      // Clear completed sub-tasks.
      await _tasksCubit.clearCompletedTasks(taskWithSubTasks.id);
      expect(state.activeList?.items, [
        task1.copyWith(completed: true),
        task2,
        task3,
        taskWithSubTasks,
        subTask1.copyWith(completed: true, deleted: true),
        subTask2,
        subTask3,
      ]);

      // Set a top-level task and a sub-task as completed.
      await _tasksCubit.updateTask(task2.copyWith(completed: true));
      await _tasksCubit.updateTask(subTask2.copyWith(completed: true));
      expect(state.activeList?.items, [
        task1.copyWith(completed: true),
        task2.copyWith(completed: true),
        task3,
        taskWithSubTasks,
        subTask1.copyWith(completed: true, deleted: true),
        subTask2.copyWith(completed: true),
        subTask3,
      ]);

      // Clear completed top-level tasks.
      await _tasksCubit.clearCompletedTasks();
      expect(state.activeList?.items, [
        task1.copyWith(completed: true, deleted: true),
        task2.copyWith(completed: true, deleted: true),
        task3,
        taskWithSubTasks,
        subTask1.copyWith(completed: true, deleted: true),
        subTask2.copyWith(completed: true),
        subTask3,
      ]);

      // Clear all sub-tasks.
      await _tasksCubit.updateTask(subTask3.copyWith(completed: true));
      expect(state.activeList?.items, [
        task1.copyWith(completed: true, deleted: true),
        task2.copyWith(completed: true, deleted: true),
        task3,
        taskWithSubTasks,
        subTask1.copyWith(completed: true, deleted: true),
        subTask2.copyWith(completed: true),
        subTask3.copyWith(completed: true),
      ]);

      // Clear completed sub-tasks.
      await _tasksCubit.clearCompletedTasks(taskWithSubTasks.id);
      expect(state.activeList?.items, [
        task1.copyWith(completed: true, deleted: true),
        task2.copyWith(completed: true, deleted: true),
        task3,
        taskWithSubTasks,
        subTask1.copyWith(completed: true, deleted: true),
        subTask2.copyWith(completed: true, deleted: true),
        subTask3.copyWith(completed: true, deleted: true),
      ]);
    });

    test('clearing task also clears its sub-tasks', () async {
      // Prepare state with tasks.
      await _tasksCubit.createList('Test List');
      _tasksCubit.setActiveList(state.taskLists.first.id);
      final task = await _tasksCubit.createTask(
        Task(title: 'Test Task 1'),
      );
      final subTask1 = await _tasksCubit.createTask(
        Task(title: 'Sub-task 1', parent: task.id),
      );
      final subTask2 = await _tasksCubit.createTask(
        Task(title: 'Sub-task 2', parent: task.id),
      );
      expect(state.activeList?.items, [
        task,
        subTask1,
        subTask2,
      ]);

      await _tasksCubit.updateTask(task.copyWith(completed: true));
      await _tasksCubit.clearCompletedTasks();
      expect(state.activeList?.items, [
        task.copyWith(completed: true, deleted: true),
        subTask1.copyWith(completed: true, deleted: true),
        subTask2.copyWith(completed: true, deleted: true),
      ]);
    });
  });
}
