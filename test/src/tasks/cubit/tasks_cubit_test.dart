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
    setUpAll(() async {
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
    });

    setUp(() {
      _tasksCubit = TasksCubit(
        _authCubit,
        _storageService,
        tasksRepository: _tasksRepository,
      );
    });

    group('clearing completed tasks works:', () {
      late Task task1;
      late Task taskWithSubTasks;
      late Task subTask1;
      late Task subTask2;

      setUp(() async {
        // Prepare state with tasks.
        _tasksCubit = TasksCubit(
          _authCubit,
          _storageService,
          tasksRepository: _tasksRepository,
        );
        await _tasksCubit.createList('Test List');
        _tasksCubit.setActiveList(state.taskLists.first.id);
        task1 = await _tasksCubit.createTask(
          Task(title: 'Test Task 1'),
        );
        taskWithSubTasks = await _tasksCubit.createTask(
          Task(title: 'Test Task with sub-tasks'),
        );
        subTask1 = await _tasksCubit.createTask(
          Task(title: 'Sub-task 1', parent: taskWithSubTasks.id),
        );
        subTask2 = await _tasksCubit.createTask(
          Task(title: 'Sub-task 2', parent: taskWithSubTasks.id),
        );
      });

      test('none are completed initially', () {
        expect(state.activeList?.items, [
          Task(
            title: 'Test Task 1',
            id: task1.id,
            index: 0,
            updated: task1.updated,
          ),
          Task(
            title: 'Test Task with sub-tasks',
            id: taskWithSubTasks.id,
            index: 1,
            updated: taskWithSubTasks.updated,
          ),
          Task(
            title: 'Sub-task 1',
            id: subTask1.id,
            parent: taskWithSubTasks.id,
            index: 0,
            updated: subTask1.updated,
          ),
          Task(
            title: 'Sub-task 2',
            id: subTask2.id,
            parent: taskWithSubTasks.id,
            index: 1,
            updated: subTask2.updated,
          ),
        ]);
      });

      test('clearing completed sub-tasks works', () async {
        task1 = await _tasksCubit.updateTask(task1.copyWith(completed: true));
        subTask1 = await _tasksCubit.updateTask(
          subTask1.copyWith(completed: true),
        );
        await _tasksCubit.clearCompletedTasks(taskWithSubTasks.id);
        expect(state.activeList?.items, [
          Task(
            title: 'Test Task 1',
            id: task1.id,
            index: 0,
            updated: task1.updated,
            completed: true,
          ),
          Task(
            title: 'Test Task with sub-tasks',
            id: taskWithSubTasks.id,
            index: 1,
            updated: taskWithSubTasks.updated,
          ),
          Task(
            title: 'Sub-task 1',
            id: subTask1.id,
            parent: taskWithSubTasks.id,
            index: 0,
            updated: subTask1.updated,
            completed: true,
            deleted: true,
          ),
          Task(
            title: 'Sub-task 2',
            id: subTask2.id,
            parent: taskWithSubTasks.id,
            index: 1,
            updated: subTask2.updated,
          ),
        ]);
      });

      test('clearing completed top-level tasks works', () async {
        // Set a top-level task and a sub-task as completed.
        task1 = await _tasksCubit.updateTask(task1.copyWith(completed: true));
        subTask1 = await _tasksCubit.updateTask(
          subTask1.copyWith(completed: true),
        );
        // Clear completed top-level tasks.
        await _tasksCubit.clearCompletedTasks();
        expect(state.activeList?.items, [
          Task(
            title: 'Test Task 1',
            id: task1.id,
            index: 0,
            updated: task1.updated,
            completed: true,
            deleted: true,
          ),
          Task(
            title: 'Test Task with sub-tasks',
            id: taskWithSubTasks.id,
            index: 1,
            updated: taskWithSubTasks.updated,
          ),
          Task(
            title: 'Sub-task 1',
            id: subTask1.id,
            parent: taskWithSubTasks.id,
            index: 0,
            updated: subTask1.updated,
            completed: true,
            deleted: false,
          ),
          Task(
            title: 'Sub-task 2',
            id: subTask2.id,
            parent: taskWithSubTasks.id,
            index: 1,
            updated: subTask2.updated,
          ),
        ]);
      });

      test('clearing completed top-level task also clears sub-tasks', () async {
        // Set a top-level task with sub-tasks as completed.
        taskWithSubTasks = await _tasksCubit.updateTask(
          taskWithSubTasks.copyWith(completed: true),
        );
        // Clear completed top-level tasks.
        await _tasksCubit.clearCompletedTasks();
        expect(state.activeList?.items, [
          Task(
            title: 'Test Task 1',
            id: task1.id,
            index: 0,
            updated: task1.updated,
          ),
          Task(
            title: 'Test Task with sub-tasks',
            id: taskWithSubTasks.id,
            index: 1,
            updated: taskWithSubTasks.updated,
            completed: true,
            deleted: true,
          ),
          Task(
            title: 'Sub-task 1',
            id: subTask1.id,
            parent: taskWithSubTasks.id,
            index: 0,
            updated: subTask1.updated,
            completed: true,
            deleted: true,
          ),
          Task(
            title: 'Sub-task 2',
            id: subTask2.id,
            parent: taskWithSubTasks.id,
            index: 1,
            updated: subTask2.updated,
            completed: true,
            deleted: true,
          ),
        ]);
      });
    });

    test('reordering tasks works', () async {
      // Prepare state with tasks.
      await _tasksCubit.createList('Test List');
      _tasksCubit.setActiveList(state.taskLists.first.id);
      final task1 = await _tasksCubit.createTask(
        Task(
          title: 'Test Task 1',
          index: 0,
        ),
      );
      final task2 = await _tasksCubit.createTask(
        Task(
          title: 'Test Task 2',
          index: 1,
        ),
      );
      final task3 = await _tasksCubit.createTask(
        Task(
          title: 'Test Task 3',
          index: 2,
        ),
      );

      expect(state.activeList?.items, [
        task1,
        task2,
        task3,
      ]);

      // Reorder tasks.
      await _tasksCubit.reorderTasks(2, 0);
      expect(state.activeList?.items, [
        task3.copyWith(index: 0),
        task1.copyWith(index: 1),
        task2.copyWith(index: 2),
      ]);
    });
  });
}
