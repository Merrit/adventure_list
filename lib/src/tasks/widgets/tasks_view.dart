import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide PopupMenuButton, PopupMenuItem;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/core.dart';
import '../tasks.dart';

class TasksView extends StatelessWidget {
  const TasksView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return BlocConsumer<TasksCubit, TasksState>(
      listener: (context, state) {
        if (state.awaitingClearTasksUndo) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cleared completed tasks'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  tasksCubit.undoClearTasks();
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
            .where((e) => !e.deleted && e.parent == null)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TasksHeader(),
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

class _TasksHeader extends StatelessWidget {
  const _TasksHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        left: 50,
      ),
      child: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          final TaskList? taskList = state.activeList;
          if (taskList == null) return const SizedBox();

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                taskList.title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: Opacity(
                  opacity: 0.5,
                  child: Transform.scale(
                    scale: 0.9,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            if (MediaQuery.of(context).isHandset) {
                              Navigator.pushNamed(
                                context,
                                TaskListSettingsPage.routeName,
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  final mediaQuery = MediaQuery.of(context);

                                  return AlertDialog(
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: const [
                                        SizedBox(),
                                        Text('List Settings'),
                                        CloseButton(),
                                      ],
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 20.0,
                                      horizontal: 100.0,
                                    ),
                                    content: SizedBox(
                                      width: mediaQuery.size.width / 2,
                                      child: const TaskListSettingsView(),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) {
                            return [
                              PopupMenuItem(
                                onTap: () => tasksCubit.clearCompletedTasks(),
                                child: const Text('Clear completed'),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
