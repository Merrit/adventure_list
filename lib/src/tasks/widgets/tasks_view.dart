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

        final tasks = activeList.items
            .where(
              (task) => task.parent == null && task.deleted == false,
            )
            .toList();

        return SizedBox(
          width: platformIsMobile() ? null : 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TasksHeader(),
              const _NewTaskButton(),
              Expanded(
                child: CustomReorderableListView.separated(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (_, int index) {
                    final task = tasks[index];

                    return TaskTile(key: ValueKey(task), task: task);
                  },
                  shrinkWrap: true,
                  onReorder: (oldIndex, newIndex) {},
                  scrollController: ScrollController(),
                  // proxyDecorator: (Widget child, _, animation) {
                  //   return AnimatedBuilder(
                  //     child: child,
                  //     animation: animation,
                  //     builder: (BuildContext context, Widget? child) {
                  //       final animValue =
                  //           Curves.easeInOut.transform(animation.value);
                  //       final scale = lerpDouble(1, 1.05, animValue)!;
                  //       final elevation = lerpDouble(0, 6, animValue)!;
                  //       return Transform.scale(
                  //         scale: scale,
                  //         child: Material(
                  //           elevation: elevation,
                  //           // borderRadius: allSmallBorderRadius,
                  //           color: Colors.transparent,
                  //           child: child,
                  //         ),
                  //       );
                  //     },
                  //   );
                  // },
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
      callback: (value) => tasksCubit.createTask(Task(title: value)),
    );
  }
}
