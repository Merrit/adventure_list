import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide PopupMenuButton, PopupMenuItem;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../../core/core.dart';
import '../tasks.dart';

class TasksView extends StatelessWidget {
  const TasksView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final TaskList? activeList = state.activeList;
        if (activeList == null) return const SizedBox();

        final tasks = activeList //
            .items
            .where((e) => !e.deleted && e.parent == null)
            .toList();

        return SizedBox(
          width: platformIsMobile() ? null : 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TasksHeader(),
              const _NewTaskButton(),
              Expanded(
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
                          const Divider(height: 16),
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
              // if (state.activeList!.items.any((element) => element.completed))
              //   ExpansionTile(
              //     title: const Text('Completed'),
              //     children: state.activeList!.items
              //         .where((element) => element.completed)
              //         .map((e) => TaskTile(task: e))
              //         .toList(),
              //   ),
            ],
          ),
        );
      },
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
            children: [
              Text(
                taskList.title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Flexible(
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
                                child: TextButton(
                                  onPressed: () {
                                    tasksCubit.clearCompletedTasks();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Clear completed'),
                                ),
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
      callback: (value) => tasksCubit.createTask(Task(title: value)),
    );
  }
}
