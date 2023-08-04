import 'package:adventure_list/src/background_tasks/background_tasks.dart';
import 'package:adventure_list/src/home_widget/home_widget.dart';
import 'package:adventure_list/src/logs/logging_manager.dart';
import 'package:adventure_list/src/storage/storage_repository.dart';
import 'package:adventure_list/src/tasks/tasks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<HomeWidgetManager>(),
  MockSpec<StorageRepository>(),
  MockSpec<TasksRepository>(),
])
import 'background_tasks_service_test.mocks.dart';

var mockHomeWidgetManager = MockHomeWidgetManager();
var mockStorageRepository = MockStorageRepository();
var mockTasksRepository = MockTasksRepository();

void main() {
  group('BackgroundTasksService:', () {
    setUpAll(() async {
      await LoggingManager.initialize(verbose: false);
    });

    setUp(() {
      reset(mockHomeWidgetManager);
      reset(mockStorageRepository);
      reset(mockTasksRepository);
    });

    test('refreshData returns false if the remote repository returns null', () async {
      when(mockTasksRepository.getAll()).thenAnswer((_) async => null);

      final service = BackgroundTasksService(
        mockHomeWidgetManager,
        mockStorageRepository,
        mockTasksRepository,
      );

      final result = await service.refreshData();

      expect(result, false);
    });

    test('refreshData returns false if the remote repository returns an empty list',
        () async {
      when(mockTasksRepository.getAll()).thenAnswer((_) async => []);

      final service = BackgroundTasksService(
        mockHomeWidgetManager,
        mockStorageRepository,
        mockTasksRepository,
      );

      final result = await service.refreshData();

      expect(result, false);
    });

    test('refreshData returns true if the remote repository returns a non-empty list',
        () async {
      when(mockTasksRepository.getAll()).thenAnswer((_) async => [
            TaskList(
              id: 'tasklist-1',
              title: 'Task List 1',
              index: 0,
              items: [
                Task(
                  taskListId: 'tasklist-1',
                  title: 'Task 1',
                  description: 'Description 1',
                  completed: false,
                ),
                Task(
                  taskListId: 'tasklist-1',
                  title: 'Task 2',
                  description: 'Description 2',
                  completed: false,
                ),
              ],
            ),
          ]);

      final service = BackgroundTasksService(
        mockHomeWidgetManager,
        mockStorageRepository,
        mockTasksRepository,
      );

      final result = await service.refreshData();

      expect(result, true);
    });
  });
}
