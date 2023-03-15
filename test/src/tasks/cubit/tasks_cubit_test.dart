import 'package:adventure_list/src/authentication/authentication.dart';
import 'package:adventure_list/src/logs/logs.dart';
import 'package:adventure_list/src/storage/storage_repository.dart';
import 'package:adventure_list/src/tasks/tasks.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockAuthenticationCubit extends MockCubit<AuthenticationState>
    implements AuthenticationCubit {}

class MockStorageRepository extends Mock implements StorageRepository {}

class MockTasksRepository extends Mock implements TasksRepository {}

class MockUuid extends Mock implements Uuid {}

class FakeTaskList extends Fake implements TaskList {}

class FakeTask extends Fake implements Task {}

late MockAuthenticationCubit _authCubit;
late MockStorageRepository _storageRepository;
late MockTasksRepository _tasksRepository;
MockUuid _uuid = MockUuid();

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
    registerFallbackValue(FakeTaskList());
    registerFallbackValue(FakeTask());
    registerFallbackValue(TaskList(
      items: const [],
      id: '',
      index: 0,
      title: '',
    ));
    registerFallbackValue(Task(
      id: '',
      index: 0,
      title: '',
      taskListId: '',
      updated: DateTime.now(),
      completed: false,
      deleted: false,
      description: null,
      dueDate: null,
      parent: null,
    ));

    await LoggingManager.initialize(verbose: false);
  });

  group('TasksCubit:', () {
    late TasksCubit testCubit;

    setUp(() async {
      /* -------------------------------- AuthCubit ------------------------------- */
      _authCubit = MockAuthenticationCubit();
      when(() => _authCubit.state).thenReturn(defaultAuthState);

      /* ----------------------------- TasksRepository ---------------------------- */
      _tasksRepository = MockTasksRepository();
      when(() => _tasksRepository.getAll()).thenAnswer((_) async => []);
      when(() => _tasksRepository.createList(any()))
          .thenAnswer((invokation) async => TaskList(
                id: UniqueKey().toString(),
                index: 0,
                items: const [],
                title: (invokation.positionalArguments.first as TaskList).title,
              ));
      when(() => _tasksRepository.deleteList(id: any(named: 'id')))
          .thenAnswer((_) async => true);
      when(() => _tasksRepository.updateList(list: any(named: 'list')))
          .thenAnswer((_) async =>
              TaskList(id: 'id', index: 0, items: const [], title: ''));
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

      /* ----------------------------- StorageRepository ----------------------------- */
      _storageRepository = MockStorageRepository();
      StorageRepository.instance = _storageRepository;
      when(() => _storageRepository.delete(any(),
          storageArea: any(named: 'storageArea'))).thenAnswer((_) async {});
      when(() => _storageRepository.getStorageAreaValues(any())).thenAnswer(
        (_) async => [],
      );
      when(() => _storageRepository.get(
            any(),
            storageArea: any(named: 'storageArea'),
          )).thenAnswer((_) async => null);
      when(() => _storageRepository.saveStorageAreaValues(
            storageArea: any(named: 'storageArea'),
            entries: any(named: 'entries'),
          )).thenAnswer((_) async {});
      when(() => _storageRepository.save(
            key: any(named: 'key'),
            value: any(named: 'value'),
            storageArea: any(named: 'storageArea'),
          )).thenAnswer((_) async {});

      // Mock the uuid generator
      when(() => _uuid.v4()).thenReturn('test-uuid');

      testCubit = TasksCubit(
        _authCubit,
        tasksRepository: _tasksRepository,
        uuid: _uuid,
      );

      while (testCubit.state.loading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    });

    test('singleton instance is accessible', () {
      expect(tasksCubit, isNotNull);
    });

    blocTest<TasksCubit, TasksState>(
      'initial state is correct',
      build: () => TasksCubit(
        _authCubit,
        tasksRepository: _tasksRepository,
      ),
      expect: () => [TasksState.initial().copyWith(loading: false)],
    );

    blocTest<TasksCubit, TasksState>(
      'createList() creates a new task list',
      setUp: () {
        when(() => _tasksRepository.createList(any())).thenAnswer(
          (_) async => TaskList(
            id: 'test-list-id-5',
            title: 'New List',
            index: 0,
            items: [],
          ),
        );

        when(() => _uuid.v4()).thenReturn('temp-test-list-id-5');
      },
      build: () => testCubit,
      act: (cubit) => cubit.createList('New List'),
      verify: (cubit) {
        verify(() => _tasksRepository.createList(any())).called(1);
        expect(cubit.state.taskLists.length, 1);
        expect(cubit.state.taskLists.first.id, 'test-list-id-5');
      },
      expect: () => [
        TasksState(
          activeList: TaskList(
            id: 'temp-test-list-id-5',
            title: 'New List',
            index: 0,
            items: [],
          ),
          loading: false,
          taskLists: [
            TaskList(
              id: 'temp-test-list-id-5',
              title: 'New List',
              index: 0,
              items: [],
            ),
          ],
        ),
        TasksState(
          activeList: TaskList(
            id: 'test-list-id-5',
            title: 'New List',
            index: 0,
            items: [],
            synced: true,
          ),
          loading: false,
          taskLists: [
            TaskList(
              id: 'test-list-id-5',
              title: 'New List',
              index: 0,
              items: [],
              synced: true,
            ),
          ],
        ),
      ],
    );

    blocTest<TasksCubit, TasksState>(
      'createList() reverts to previous state if an error occurs',
      setUp: () {
        when(() => _tasksRepository.createList(any()))
            .thenAnswer((_) async => null);
        when(() => _uuid.v4()).thenReturn('test-list-id-2');
      },
      build: () => testCubit,
      seed: () => TasksState(
        activeList: TaskList(
          id: 'test-list-id-1',
          title: 'Chores',
          index: 0,
          items: [],
        ),
        loading: false,
        taskLists: [
          TaskList(
            id: 'test-list-id-1',
            title: 'Chores',
            index: 0,
            items: [],
          ),
        ],
      ),
      act: (cubit) => cubit.createList('New List'),
      verify: (cubit) {
        verify(() => _tasksRepository.createList(any())).called(1);
        expect(cubit.state.taskLists.length, 1);
        expect(cubit.state.taskLists.first.id, 'test-list-id-1');
      },
      expect: () => [
        TasksState(
          activeList: TaskList(
            id: 'test-list-id-2',
            title: 'New List',
            index: 1,
            items: [],
          ),
          loading: false,
          taskLists: [
            TaskList(
              id: 'test-list-id-1',
              title: 'Chores',
              index: 0,
              items: [],
            ),
            TaskList(
              id: 'test-list-id-2',
              title: 'New List',
              index: 1,
              items: [],
            ),
          ],
        ),
        TasksState(
          activeList: TaskList(
            id: 'test-list-id-1',
            title: 'Chores',
            index: 0,
            items: [],
          ),
          loading: false,
          taskLists: [
            TaskList(
              id: 'test-list-id-1',
              title: 'Chores',
              index: 0,
              items: [],
            ),
          ],
        ),
      ],
    );

    blocTest<TasksCubit, TasksState>(
      'updateList() updates a task list',
      setUp: () {
        when(() => _tasksRepository.updateList(list: any(named: 'list')))
            .thenAnswer(
          (_) async => TaskList(
            id: 'test-list-id-5',
            title: 'Updated List',
            index: 0,
            items: [],
          ),
        );
      },
      build: () => testCubit,
      seed: () => TasksState(
        activeList: TaskList(
          id: 'test-list-id-5',
          title: 'New List',
          index: 0,
          items: [],
        ),
        loading: false,
        taskLists: [
          TaskList(
            id: 'test-list-id-5',
            title: 'New List',
            index: 0,
            items: [],
          ),
        ],
      ),
      act: (cubit) => cubit.updateList(
        TaskList(
          id: 'test-list-id-5',
          title: 'Updated List',
          index: 0,
          items: [],
        ),
      ),
      verify: (cubit) {
        verify(() => _tasksRepository.updateList(list: any(named: 'list')))
            .called(1);
        expect(cubit.state.taskLists.length, 1);
        expect(cubit.state.taskLists.first.id, 'test-list-id-5');
        expect(cubit.state.taskLists.first.title, 'Updated List');
      },
      expect: () => [
        TasksState(
          activeList: TaskList(
            id: 'test-list-id-5',
            title: 'Updated List',
            index: 0,
            items: [],
          ),
          loading: false,
          taskLists: [
            TaskList(
              id: 'test-list-id-5',
              title: 'Updated List',
              index: 0,
              items: [],
            ),
          ],
        ),
      ],
    );

    blocTest<TasksCubit, TasksState>(
      'deleteList() deletes a task list',
      setUp: () {
        when(() => _tasksRepository.deleteList(id: any(named: 'id')))
            .thenAnswer((_) async => true);
      },
      build: () => testCubit,
      seed: () => TasksState(
        activeList: TaskList(
          id: 'test-list-id-5',
          title: 'New List',
          index: 0,
          items: [],
        ),
        loading: false,
        taskLists: [
          TaskList(
            id: 'test-list-id-5',
            title: 'New List',
            index: 0,
            items: [],
          ),
        ],
      ),
      act: (cubit) => cubit.deleteList(),
      verify: (cubit) {
        verify(() => _tasksRepository.deleteList(id: any(named: 'id')))
            .called(1);
        expect(cubit.state.taskLists.length, 0);
      },
      expect: () => [
        const TasksState(
          activeList: null,
          loading: false,
          taskLists: [],
        ),
      ],
    );

    blocTest<TasksCubit, TasksState>(
      'createTask() creates a new task',
      setUp: () {
        when(() => _tasksRepository.createTask(
              taskListId: any(named: 'taskListId'),
              newTask: any(named: 'newTask'),
            )).thenAnswer(
          (_) async => Task(
            id: 'test-task-id-5',
            taskListId: 'test-list-id-5',
            title: 'New Task',
            index: 0,
            completed: false,
          ),
        );

        when(() => _uuid.v4()).thenReturn('temp-test-task-id-5');
      },
      build: () => testCubit,
      seed: () => TasksState(
        activeList: TaskList(
          id: 'test-list-id-5',
          title: 'New List',
          index: 0,
          items: [],
        ),
        loading: false,
        taskLists: [
          TaskList(
            id: 'test-list-id-5',
            title: 'New List',
            index: 0,
            items: [],
          ),
        ],
      ),
      act: (cubit) => cubit.createTask(Task(
        id: 'temp-test-task-id-5',
        taskListId: 'test-list-id-5',
        title: 'New Task',
        index: 0,
        completed: false,
      )),
      verify: (cubit) {
        verify(() => _tasksRepository.createTask(
              taskListId: any(named: 'taskListId'),
              newTask: any(named: 'newTask'),
            )).called(1);
        expect(cubit.state.activeList?.items.length, 1);
        expect(cubit.state.activeList?.items.first.id, 'test-task-id-5');
        expect(cubit.state.activeList?.items.first.title, 'New Task');
      },
    );

    test('deleting list works', () async {
      await testCubit.createList('Chores');
      await testCubit.createList('Tasks');
      expect(testCubit.state.taskLists.length, 2);
      expect(testCubit.state.activeList!.title, 'Tasks');

      await testCubit.deleteList();
      expect(testCubit.state.taskLists.length, 1);
      expect(testCubit.state.taskLists.first.title, 'Chores');
      expect(testCubit.state.activeList, null);
    });

    test('reordering lists works', () async {
      await testCubit.createList('Tasks');
      await testCubit.createList('Chores');
      await testCubit.createList('Work');
      expect(testCubit.state.taskLists.length, 3);
      expect(testCubit.state.taskLists[0].title, 'Tasks');
      expect(testCubit.state.taskLists[1].title, 'Chores');
      expect(testCubit.state.taskLists[2].title, 'Work');
      expect(testCubit.state.taskLists[0].index, 0);
      expect(testCubit.state.taskLists[1].index, 1);
      expect(testCubit.state.taskLists[2].index, 2);

      await testCubit.reorderLists(2, 0);
      expect(testCubit.state.taskLists.length, 3);
      expect(testCubit.state.taskLists[0].title, 'Work');
      expect(testCubit.state.taskLists[1].title, 'Tasks');
      expect(testCubit.state.taskLists[2].title, 'Chores');
      expect(testCubit.state.taskLists[0].index, 0);
      expect(testCubit.state.taskLists[1].index, 1);
      expect(testCubit.state.taskLists[2].index, 2);
    });

    test('reordering tasks works', () async {
      // Prepare state with tasks.
      await testCubit.createList('Test List');
      testCubit.setActiveList(testCubit.state.taskLists.first.id);
      final task1 = await testCubit.createTask(
        Task(
          taskListId: 'test-list-id',
          title: 'Test Task 1',
          index: 0,
        ),
      );
      final task2 = await testCubit.createTask(
        Task(
          taskListId: 'test-list-id',
          title: 'Test Task 2',
          index: 1,
        ),
      );
      final task3 = await testCubit.createTask(
        Task(
          taskListId: 'test-list-id',
          title: 'Test Task 3',
          index: 2,
        ),
      );

      expect(testCubit.state.activeList?.items, [
        task1,
        task2,
        task3,
      ]);

      // Reorder tasks.
      await testCubit.reorderTasks(2, 0);
      expect(testCubit.state.activeList?.items, [
        task3.copyWith(index: 0),
        task1.copyWith(index: 1),
        task2.copyWith(index: 2),
      ]);
    });

    test('setting active task works', () async {
      await testCubit.createList('Tasks');
      final task = await testCubit.createTask(
        Task(
          taskListId: 'test-list-id',
          title: 'Do a thing',
        ),
      );
      expect(testCubit.state.activeTask, null);
      testCubit.setActiveTask(task.id);
      expect(testCubit.state.activeTask, task);
      testCubit.setActiveTask(null);
      expect(testCubit.state.activeTask, null);
    });

    test('undoClearTasks works', () async {
      await testCubit.createList('Tasks');
      final Task task = await testCubit.createTask(
        Task(
          taskListId: 'test-list-id',
          title: 'Do a thing',
        ),
      );
      await testCubit.updateTask(task.copyWith(completed: true));
      testCubit.clearCompletedTasks();
      await Future.delayed(const Duration(seconds: 3));
      testCubit.undoClearTasks();
      expect(testCubit.state.activeList!.items.first,
          task.copyWith(completed: true));
    });

    test('updating sub-task works', () async {
      await testCubit.createList('Tasks');
      final Task task = await testCubit.createTask(
        Task(
          taskListId: 'test-list-id',
          title: 'Parent task',
        ),
      );
      final subTask = await testCubit.createTask(
        Task(
          taskListId: 'test-list-id',
          title: 'sub-task',
          parent: task.id,
        ),
      );

      expect(
        testCubit.state.activeList!.items.getTaskById(task.id)!.completed,
        isFalse,
      );

      await testCubit.updateTask(subTask.copyWith(completed: true));

      expect(
        testCubit.state.activeList!.items.getTaskById(subTask.id)!.completed,
        isTrue,
      );
    });
  });
}
