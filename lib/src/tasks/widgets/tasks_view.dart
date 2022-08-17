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
        if (state.activeList == null) return const SizedBox();

        return SizedBox(
          width: platformIsMobile() ? null : 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TasksHeader(),
              const _NewTaskButton(),
              Expanded(
                child: ReorderableListView(
                  scrollController: ScrollController(),
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {},
                  children: state.activeList!.items
                      .where(
                        (task) => task.parent == null && task.deleted == false,
                      )
                      .map((e) => TaskTile(key: ValueKey(e), task: e))
                      .toList(),
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
          return Row(
            children: [
              Text(
                state.activeList!.title,
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
                          onPressed: () => Navigator.pushNamed(
                            context,
                            TaskListSettingsPage.routeName,
                          ),
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) {
                            return [
                              PopupMenuItem(
                                child: TextButton(
                                  onPressed: () =>
                                      tasksCubit.clearCompletedTasks(),
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
