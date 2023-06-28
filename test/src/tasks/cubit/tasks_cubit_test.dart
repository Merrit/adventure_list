import 'package:adventure_list/src/authentication/authentication.dart';
import 'package:adventure_list/src/home_widget/home_widget.dart';
import 'package:adventure_list/src/logs/logging_manager.dart';
import 'package:adventure_list/src/storage/storage_repository.dart';
import 'package:adventure_list/src/tasks/tasks.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

@GenerateNiceMocks([
  MockSpec<AuthenticationCubit>(),
  MockSpec<GoogleAuth>(),
  MockSpec<HomeWidgetManager>(),
  MockSpec<StorageRepository>(),
  MockSpec<TasksRepository>(),
  MockSpec<Uuid>(),
])
import 'tasks_cubit_test.mocks.dart';

class FakeTaskList extends Fake implements TaskList {}

class FakeTask extends Fake implements Task {}

MockAuthenticationCubit _authCubit = MockAuthenticationCubit();
MockGoogleAuth _googleAuth = MockGoogleAuth();
MockHomeWidgetManager _homeWidgetManager = MockHomeWidgetManager();
MockStorageRepository _storageRepository = MockStorageRepository();
MockTasksRepository _tasksRepository = MockTasksRepository();
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
    await LoggingManager.initialize(verbose: false);
  });

  group('TasksCubit:', () {
    late TasksCubit testCubit;

    setUp(() async {
      /* -------------------------------- AuthCubit ------------------------------- */
      reset(_authCubit);
      when(_authCubit.state).thenReturn(defaultAuthState);
      when(_authCubit.state).thenReturn(defaultAuthState);

      /* -------------------------------- GoogleAuth ------------------------------- */
      reset(_googleAuth);
      when(_googleAuth.signin()).thenAnswer((_) async => null);

      /* ----------------------------- HomeWidgetManager ---------------------------- */
      reset(_homeWidgetManager);
      when(_homeWidgetManager.updateHomeWidget(any, any))
          .thenAnswer((_) async {});

      /* ----------------------------- TasksRepository ---------------------------- */
      reset(_tasksRepository);
      when(_tasksRepository.getAll()).thenAnswer((_) async => []);
      when(_tasksRepository.createList(any))
          .thenAnswer((invokation) async => TaskList(
                id: UniqueKey().toString(),
                index: 0,
                items: const [],
                title: (invokation.positionalArguments.first as TaskList).title,
              ));
      when(_tasksRepository.deleteList(id: anyNamed('id')))
          .thenAnswer((_) async => true);
      when(_tasksRepository.updateList(list: anyNamed('list'))).thenAnswer(
          (_) async =>
              TaskList(id: 'id', index: 0, items: const [], title: ''));
      when(_tasksRepository.createTask(
              newTask: anyNamed('newTask'), taskListId: anyNamed('taskListId')))
          .thenAnswer((invokation) async {
        final providedTask =
            invokation.namedArguments[const Symbol('newTask')] as Task;
        return providedTask.copyWith(id: UniqueKey().toString());
      });
      when(_tasksRepository.updateTask(
              taskListId: anyNamed('taskListId'),
              updatedTask: anyNamed('updatedTask')))
          .thenAnswer((invokation) async {
        final providedTask =
            invokation.namedArguments[const Symbol('updatedTask')] as Task;
        return providedTask;
      });

      /* ----------------------------- StorageRepository ----------------------------- */
      reset(_storageRepository);
      StorageRepository.instance = _storageRepository;
      when(_storageRepository.delete(any, storageArea: anyNamed('storageArea')))
          .thenAnswer((_) async {});
      when(_storageRepository.getStorageAreaValues(any))
          .thenAnswer((_) async => []);
      when(_storageRepository.get(any, storageArea: anyNamed('storageArea')))
          .thenAnswer((_) async => null);
      when(_storageRepository.saveStorageAreaValues(
        storageArea: anyNamed('storageArea'),
        entries: anyNamed('entries'),
      )).thenAnswer((_) async {});
      when(_storageRepository.save(
        key: anyNamed('key'),
        value: anyNamed('value'),
        storageArea: anyNamed('storageArea'),
      )).thenAnswer((_) async {});

      // Mock the uuid generator
      when(_uuid.v4()).thenReturn('test-uuid');

      testCubit = TasksCubit(
        _authCubit,
        _googleAuth,
        _homeWidgetManager,
        tasksRepository: _tasksRepository,
        uuid: _uuid,
      );

      while (testCubit.state.loading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    });

    const testTaskListId = 'test-task-list-id';

    final testTaskList = TaskList(
      id: testTaskListId,
      title: 'Test Task List',
      index: 0,
      items: const [],
    );

    final task1 = Task(
      id: 'test-task-id-1',
      title: 'Test Task 1',
      index: 0,
      taskListId: testTaskListId,
      updated: DateTime.now(),
      completed: false,
      description: null,
      dueDate: null,
      parent: null,
    );

    final task2 = Task(
      id: 'test-task-id-2',
      title: 'Test Task 2',
      index: 1,
      taskListId: testTaskListId,
      updated: DateTime.now(),
      completed: false,
      description: null,
      dueDate: null,
      parent: null,
    );

    final task3 = Task(
      id: 'test-task-id-3',
      title: 'Test Task 3',
      index: 2,
      taskListId: testTaskListId,
      updated: DateTime.now(),
      completed: false,
      description: null,
      dueDate: null,
      parent: null,
    );

    final task4 = Task(
      id: 'test-task-id-4',
      title: 'Test Task 4',
      index: 3,
      taskListId: testTaskListId,
      updated: DateTime.now(),
      completed: false,
      description: null,
      dueDate: null,
      parent: null,
    );

    final subTask1 = Task(
      id: 'test-sub-task-id-1',
      title: 'Test Sub Task 1',
      index: 0,
      taskListId: testTaskListId,
      updated: DateTime.now(),
      completed: false,
      description: null,
      dueDate: null,
      parent: task1.id,
    );

    final subTask2 = Task(
      id: 'test-sub-task-id-2',
      title: 'Test Sub Task 2',
      index: 1,
      taskListId: testTaskListId,
      updated: DateTime.now(),
      completed: false,
      description: null,
      dueDate: null,
      parent: task1.id,
    );

    final subTask3 = Task(
      id: 'test-sub-task-id-3',
      title: 'Test Sub Task 3',
      index: 2,
      taskListId: testTaskListId,
      updated: DateTime.now(),
      completed: false,
      description: null,
      dueDate: null,
      parent: task1.id,
    );

    final subTask4 = Task(
      id: 'test-sub-task-id-4',
      title: 'Test Sub Task 4',
      index: 0,
      taskListId: testTaskListId,
      updated: DateTime.now(),
      completed: false,
      description: null,
      dueDate: null,
      parent: task3.id,
    );

    const testTaskListId2 = 'test-task-list-id-2';

    final testTaskList2 = TaskList(
      id: testTaskListId2,
      title: 'Test Task List 2',
      index: 1,
      items: const [],
    );

    final task1ForTaskList2 = Task(
      id: 'test-task-id-1-for-task-list-2',
      title: 'Test Task 1 for Task List 2',
      index: 0,
      taskListId: testTaskListId2,
      updated: DateTime.now(),
      completed: false,
      description: null,
      dueDate: null,
      parent: null,
    );

    final task2ForTaskList2 = Task(
      id: 'test-task-id-2-for-task-list-2',
      title: 'Test Task 2 for Task List 2',
      index: 1,
      taskListId: testTaskListId2,
      updated: DateTime.now(),
      completed: false,
      description: null,
      dueDate: null,
      parent: null,
    );

    test('singleton instance is accessible', () {
      expect(tasksCubit, isNotNull);
    });

    blocTest<TasksCubit, TasksState>(
      'initial state is correct',
      build: () => TasksCubit(
        _authCubit,
        _googleAuth,
        _homeWidgetManager,
        tasksRepository: _tasksRepository,
      ),
      expect: () => [TasksState.initial().copyWith(loading: false)],
    );

    group('clearCompletedTasks():', () {
      test('works as expected', () async {
        when(_tasksRepository.deleteTask(
                taskListId: anyNamed('taskListId'), taskId: anyNamed('taskId')))
            .thenAnswer((_) async => true);

        // Seed the state with a task list and tasks
        final taskList = testTaskList.copyWith(
          items: [
            task1.copyWith(completed: true),
            task2.copyWith(completed: true),
            task3.copyWith(completed: false),
            task4.copyWith(completed: false),
            subTask1.copyWith(completed: false),
            subTask2.copyWith(completed: true),
            subTask3.copyWith(completed: false),
            subTask4.copyWith(completed: false),
          ],
        );
        testCubit.emit(TasksState(
          loading: false,
          activeList: taskList,
          taskLists: [taskList],
        ));

        // Clear the completed tasks
        await testCubit.clearCompletedTasks();

        // Verify that the tasks that were not completed remain
        final updatedTaskList = testCubit.state.activeList;
        if (updatedTaskList == null) fail('Task list is null');
        expect(updatedTaskList.items.length, 3);
        expect(updatedTaskList.items[0].id, task3.id);
        expect(updatedTaskList.items[0].completed, false);
        expect(updatedTaskList.items[0].index, 0);
        expect(updatedTaskList.items[1].id, task4.id);
        expect(updatedTaskList.items[1].completed, false);
        expect(updatedTaskList.items[1].index, 1);
        expect(updatedTaskList.items[2].id, subTask4.id);
        expect(updatedTaskList.items[2].completed, false);
        expect(updatedTaskList.items[2].index, 0);
      });

      test('does nothing if there are no completed tasks', () async {
        // Seed the state with a task list and tasks
        final taskList = testTaskList.copyWith(
          items: [
            task1,
            task2,
            task3,
            task4,
            subTask1,
            subTask2,
            subTask3,
            subTask4,
          ],
        );
        testCubit.emit(TasksState(
          loading: false,
          activeList: taskList,
          taskLists: [taskList],
        ));

        // Clear the completed tasks
        await testCubit.clearCompletedTasks();

        // Verify that the tasks that were not completed remain
        expect(testCubit.state.activeList, taskList);
      });

      test('only clears completed tasks in the active list', () async {
        final taskList1 = TaskList(
          id: 'test-task-list-id-1',
          title: 'Test Task List 1',
          index: 0,
          items: [
            task1.copyWith(completed: true),
            task2.copyWith(completed: false),
          ],
        );

        final taskList2 = TaskList(
          id: 'test-task-list-id-2',
          title: 'Test Task List 2',
          index: 1,
          items: [
            task3.copyWith(completed: false),
            task4.copyWith(completed: true),
          ],
        );

        // Seed the state with two task lists and tasks
        testCubit.emit(TasksState(
          loading: false,
          activeList: taskList1,
          taskLists: [taskList1, taskList2],
        ));

        // Clear the completed tasks
        await testCubit.clearCompletedTasks();

        // Verify that only the completed task in the active list was cleared.
        // The completed task in the other list should remain.
        final updatedTaskList1 = testCubit.state.taskLists.first;
        expect(updatedTaskList1.items.length, 1);
        expect(
          updatedTaskList1.items[0],
          taskList1.items[1].copyWith(index: 0),
        );
        expect(testCubit.state.taskLists[1], taskList2);
      });

      test("if provided a parentId, only clears that task's subtasks",
          () async {
        final taskList = testTaskList.copyWith(
          items: [
            task1.copyWith(completed: true),
            task2,
            task3,
            task4,
            subTask1.copyWith(completed: true),
            subTask2.copyWith(completed: true),
            subTask3,
            subTask4,
          ],
        );

        // Seed the state with a task list and tasks
        testCubit.emit(TasksState(
          loading: false,
          activeList: taskList,
          taskLists: [taskList],
        ));

        // Clear the completed tasks
        await testCubit.clearCompletedTasks(parentId: task1.id);
        expect(testCubit.state.activeList?.items, [
          task1.copyWith(completed: true),
          task2,
          task3,
          task4,
          subTask3.copyWith(index: 0),
          subTask4,
        ]);
      });
    });

    blocTest<TasksCubit, TasksState>(
      'createList() creates a new task list',
      setUp: () {
        when(_tasksRepository.createList(any)).thenAnswer(
          (_) async => TaskList(
            id: 'test-list-id-5',
            title: 'New List',
            index: 0,
            items: [],
          ),
        );

        when(_uuid.v4()).thenReturn('temp-test-list-id-5');
      },
      build: () => testCubit,
      act: (cubit) => cubit.createList('New List'),
      verify: (cubit) {
        verify(_tasksRepository.createList(any)).called(1);
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
        when(_tasksRepository.createList(any)).thenAnswer((_) async => null);
        when(_uuid.v4()).thenReturn('test-list-id-2');
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
        verify(_tasksRepository.createList(any)).called(1);
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
        when(_tasksRepository.updateList(list: anyNamed('list'))).thenAnswer(
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
        verify(_tasksRepository.updateList(list: anyNamed('list'))).called(1);
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
        when(_tasksRepository.deleteList(id: anyNamed('id')))
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
        verify(_tasksRepository.deleteList(id: anyNamed('id'))).called(1);
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
        when(_tasksRepository.createTask(
          taskListId: anyNamed('taskListId'),
          newTask: anyNamed('newTask'),
        )).thenAnswer(
          (_) async => Task(
            id: 'test-task-id-5',
            taskListId: 'test-list-id-5',
            title: 'New Task',
            index: 0,
            completed: false,
          ),
        );

        when(_uuid.v4()).thenReturn('temp-test-task-id-5');
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
        verify(_tasksRepository.createTask(
          taskListId: anyNamed('taskListId'),
          newTask: anyNamed('newTask'),
        )).called(1);
        expect(cubit.state.activeList?.items.length, 1);
        expect(cubit.state.activeList?.items.first.id, 'test-task-id-5');
        expect(cubit.state.activeList?.items.first.title, 'New Task');
      },
    );

    blocTest<TasksCubit, TasksState>(
      'createTask() reverts to previous state if task creation fails',
      setUp: () {
        when(_tasksRepository.createTask(
          taskListId: anyNamed('taskListId'),
          newTask: anyNamed('newTask'),
        )).thenAnswer((_) async => null);
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
        verify(_tasksRepository.createTask(
          taskListId: anyNamed('taskListId'),
          newTask: anyNamed('newTask'),
        )).called(1);
        expect(cubit.state.activeList?.items.length, 0);
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
        task3?.copyWith(index: 0),
        task1?.copyWith(index: 1),
        task2?.copyWith(index: 2),
      ]);
    });

    test('setActiveTask() works', () async {
      await testCubit.createList('Tasks');
      final task = await testCubit.createTask(
        Task(
          taskListId: 'test-list-id',
          title: 'Do a thing',
        ),
      );
      expect(testCubit.state.activeTask, null);
      testCubit.setActiveTask(task?.id);
      expect(testCubit.state.activeTask, task);
      testCubit.setActiveTask(null);
      expect(testCubit.state.activeTask, null);
    });

    test('setActiveTask() additionally sets active list if needed', () async {
      // Seed the cubit with state.
      final taskList1 = testTaskList.copyWith(items: [
        task1,
        task2,
      ]);

      final taskList2 = testTaskList2.copyWith(items: [
        task1ForTaskList2,
        task2ForTaskList2,
      ]);

      testCubit.emit(TasksState(
        activeList: taskList2,
        activeTask: task2ForTaskList2,
        loading: false,
        taskLists: [
          taskList1,
          taskList2,
        ],
      ));

      // Verify initial state.
      expect(testCubit.state.activeTask, task2ForTaskList2);
      expect(testCubit.state.activeList, taskList2);
      // Set active task.
      testCubit.setActiveTask(task1.id);
      expect(testCubit.state.activeTask, task1);
      expect(testCubit.state.activeList, taskList1);
    });

    test('setTaskCompleted() works', () async {
      // Seed state with tasks.
      final taskList = testTaskList.copyWith(
        items: [
          task1,
          task2,
          task3,
          task4,
          subTask1,
          subTask2,
          subTask3,
          subTask4,
        ],
      );

      testCubit.emit(TasksState(
        activeList: taskList,
        loading: false,
        taskLists: [taskList],
      ));

      // Set task completed.
      await testCubit.setTaskCompleted(task1.id, true);
      expect(testCubit.state.activeList?.items, [
        task1.copyWith(completed: true),
        task2,
        task3,
        task4,
        subTask1.copyWith(completed: true),
        subTask2.copyWith(completed: true),
        subTask3.copyWith(completed: true),
        subTask4,
      ]);

      // Set task uncompleted.
      await testCubit.setTaskCompleted(task1.id, false);
      expect(testCubit.state.activeList?.items, [
        task1,
        task2,
        task3,
        task4,
        subTask1,
        subTask2,
        subTask3,
        subTask4,
      ]);
    });

    test('undoClearCompletedTasks works', () async {
      // Seed state with tasks.
      final taskList = testTaskList.copyWith(
        items: [
          task1.copyWith(completed: true),
          task2.copyWith(completed: false),
          task3.copyWith(completed: false),
          task4.copyWith(completed: true),
          subTask1,
          subTask2,
          subTask3,
          subTask4,
        ],
      );

      testCubit.emit(TasksState(
        activeList: taskList,
        awaitingClearTasksUndo: false,
        loading: false,
        taskLists: [taskList],
      ));

      // Clear completed tasks.
      await testCubit.clearCompletedTasks();
      expect(testCubit.state.activeList?.items, [
        task2.copyWith(index: 0),
        task3.copyWith(index: 1),
        subTask4.copyWith(index: 0),
      ]);

      // Undo clear completed tasks.
      testCubit.undoClearCompletedTasks();
      expect(testCubit.state.activeList?.items, taskList.items);
    });

    test('updating sub-task works', () async {
      // Seed the state.
      final taskList = testTaskList.copyWith(
        items: [
          task1,
          task2,
          task3,
          task4,
          subTask1,
          subTask2,
          subTask3,
          subTask4,
        ],
      );

      testCubit.emit(TasksState(
        activeList: taskList,
        activeTask: task1,
        loading: false,
        taskLists: [taskList],
      ));

      // Update sub-task.
      await testCubit.updateTask(subTask1.copyWith(completed: true));

      expect(testCubit.state.taskLists.length, 1);

      final updatedTaskList = testCubit.state.taskLists.first;
      expect(updatedTaskList.items, [
        task1,
        task2,
        task3,
        task4,
        subTask1.copyWith(completed: true),
        subTask2,
        subTask3,
        subTask4,
      ]);
    });
  });
}
