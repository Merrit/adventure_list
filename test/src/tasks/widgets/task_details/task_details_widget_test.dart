import 'package:adventure_list/src/tasks/tasks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<TasksCubit>(),
])
import 'task_details_widget_test.mocks.dart';

final initialTask = Task(
  id: '1',
  index: 0,
  title: 'Task 1',
  description: 'Task 1 description',
  taskListId: '1',
);

final initialTaskList = TaskList(
  id: '1',
  index: 0,
  title: 'Task List 1',
  items: [
    initialTask,
  ],
);

final initialTasksState = TasksState(
  loading: false,
  taskLists: [
    initialTaskList,
  ],
  activeList: initialTaskList,
  activeTask: initialTask,
);

MockTasksCubit mockTasksCubit = MockTasksCubit();

void main() {
  group('TaskDetailsWidget:', () {
    setUp(() {
      reset(mockTasksCubit);
      when(mockTasksCubit.state).thenReturn(initialTasksState);
    });

    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(_buildTaskDetailsWidget());

      expect(find.byType(TaskDetailsWidget), findsOneWidget);
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 1 description'), findsOneWidget);
    });
  });
}

/// Reuseable function to build the widget under test to reduce boilerplate.
BlocProvider<TasksCubit> _buildTaskDetailsWidget() {
  return BlocProvider<TasksCubit>.value(
    value: mockTasksCubit,
    child: const MaterialApp(
      home: Scaffold(
        body: TaskDetailsWidget(),
      ),
    ),
  );
}
