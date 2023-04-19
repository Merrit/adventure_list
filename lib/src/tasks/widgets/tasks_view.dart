import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide PopupMenuButton, PopupMenuItem;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/core.dart';
import '../../core/helpers/helpers.dart';
import '../tasks.dart';

class TasksView extends StatelessWidget {
  const TasksView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return BlocConsumer<TasksCubit, TasksState>(
      listenWhen: (previous, current) =>
          previous.awaitingClearTasksUndo != current.awaitingClearTasksUndo,
      listener: (context, state) {
        if (state.awaitingClearTasksUndo) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cleared completed tasks'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  tasksCubit.undoClearCompletedTasks();
                  ScaffoldMessenger.of(context).clearSnackBars();
                },
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final TaskList? activeList = state.activeList;
        if (activeList == null) return const _CreateSelectListPrompt();

        final tasks = activeList //
            .items
            .topLevelTasks();

        final Widget tasksHeader = (mediaQuery.isSmallScreen) //
            ? const SizedBox()
            : const Padding(
                padding: EdgeInsets.only(
                  top: 20,
                  left: 50,
                ),
                child: TasksHeader(),
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tasksHeader,
            const _NewTaskButton(),
            Expanded(
              child: SizedBox(
                width: mediaQuery.size.width,
                child: ReorderableListView.builder(
                  scrollController: ScrollController(),
                  buildDefaultDragHandles:
                      (defaultTargetPlatform == TargetPlatform.android ||
                              defaultTargetPlatform == TargetPlatform.android)
                          ? true
                          : false,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (_, int index) {
                    final task = tasks[index];

                    return Column(
                      key: ValueKey(task),
                      children: [
                        TaskTile(key: ValueKey(task), index: index, task: task),
                        if (index != tasks.length - 1)
                          SizedBox(
                            width: mediaQuery.size.width,
                            child: const Divider(height: 16),
                          ),
                        // const Divider(height: 16),
                      ],
                    );
                  },
                  itemCount: tasks.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) newIndex -= 1;
                    tasksCubit.reorderTasks(oldIndex, newIndex);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CreateSelectListPrompt extends StatelessWidget {
  const _CreateSelectListPrompt();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(50.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: double.infinity),
          Icon(Icons.arrow_back),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'Select or create a list to get started',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Button for creating new tasks.
class _NewTaskButton extends StatelessWidget {
  const _NewTaskButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextInputListTile(
      debugLabel: 'NewTaskButton FocusNode',
      leading: const Icon(Icons.add),
      placeholderText: 'New Task',
      retainFocus: true,
      callback: (value) => tasksCubit.createTask(
        Task(
          taskListId: tasksCubit.state.activeList!.id,
          title: value,
        ),
      ),
    );
  }
}
