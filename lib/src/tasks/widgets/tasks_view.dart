import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide PopupMenuButton, PopupMenuItem;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generated/locale_keys.g.dart';
import '../../core/core.dart';
import '../tasks.dart';

class TasksView extends StatelessWidget {
  const TasksView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NewTaskButton(),
            _TasksListWidget(),
            _CompletedTasksWidget(),
          ],
        );
      },
    );
  }
}

class _TasksListWidget extends StatelessWidget {
  const _TasksListWidget();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Expanded(
      child: SizedBox(
        width: mediaQuery.size.width,
        child: BlocBuilder<TasksCubit, TasksState>(
          builder: (context, state) {
            final TaskList? activeList = state.activeList;
            if (activeList == null) return const SizedBox();

            final tasks = activeList.items.topLevelTasks().incompleteTasks();

            final bool buildDefaultDragHandles =
                (defaultTargetPlatform == TargetPlatform.android ||
                        defaultTargetPlatform == TargetPlatform.android)
                    ? true
                    : false;

            return ReorderableListView.builder(
              scrollController: ScrollController(),
              buildDefaultDragHandles: buildDefaultDragHandles,
              padding: const EdgeInsets.only(
                bottom: 20,
                right: 6,
              ),
              itemBuilder: (_, int index) {
                final task = tasks[index];

                return TaskTile(key: ValueKey(task), index: index, task: task);
              },
              itemCount: tasks.length,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) newIndex -= 1;
                tasksCubit.reorderTasks(oldIndex, newIndex);
              },
            );
          },
        ),
      ),
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
        children: [
          const SizedBox(height: double.infinity),
          const Icon(Icons.arrow_back),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              LocaleKeys.getStartedPrompt.tr(),
              style: const TextStyle(
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
      placeholderText: LocaleKeys.newTask.tr(),
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

/// Collapsable area that displays completed tasks.
class _CompletedTasksWidget extends StatefulWidget {
  const _CompletedTasksWidget();

  @override
  State<_CompletedTasksWidget> createState() => _CompletedTasksWidgetState();
}

class _CompletedTasksWidgetState extends State<_CompletedTasksWidget> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final TaskList? activeList = state.activeList;
        if (activeList == null) return const SizedBox();

        final completedTasks = activeList //
            .items
            .topLevelTasks()
            .completedTasks();

        if (completedTasks.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            ListTile(
              leading: Icon(
                expanded ? Icons.arrow_drop_down : Icons.arrow_right,
              ),
              title: Text(
                '${LocaleKeys.completed.tr()} (${completedTasks.length})',
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              onTap: () {
                setState(() {
                  expanded = !expanded;
                });
              },
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState:
                  expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox(),
              secondChild: const _CompletedTasksList(),
            ),
          ],
        );
      },
    );
  }
}

/// List of completed task widgets.
class _CompletedTasksList extends StatelessWidget {
  const _CompletedTasksList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final completedTasks = state //
            .activeList
            ?.items
            .topLevelTasks()
            .completedTasks();

        if (completedTasks == null || completedTasks.isEmpty) {
          return const SizedBox();
        }

        // Calculate the height of the list based on the number of items and
        // the height of each item.
        const itemExtent = 50.0;
        final height = min(200, completedTasks.length * itemExtent).toDouble();

        // Return a list of completed tasks that has a limited height, and
        // will scroll if the list of completed tasks is too long.
        return SizedBox(
          height: height,
          child: ListView.builder(
            padding: const EdgeInsets.only(
              bottom: 20,
              right: 6,
            ),
            itemBuilder: (_, int index) {
              final task = completedTasks[index];

              return _CompletedTaskTile(task);
            },
            itemCount: completedTasks.length,
          ),
        );
      },
    );
  }
}

/// A widget representing a completed [Task].
class _CompletedTaskTile extends StatefulWidget {
  final Task task;

  const _CompletedTaskTile(this.task);

  @override
  State<_CompletedTaskTile> createState() => _CompletedTaskTileState();
}

class _CompletedTaskTileState extends State<_CompletedTaskTile> {
  late final Task task;
  late final TasksCubit tasksCubit;

  @override
  void initState() {
    super.initState();
    task = widget.task;
    tasksCubit = context.read<TasksCubit>();
  }

  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: ListTile(
        leading: IconButton(
          icon: const Icon(Icons.check),
          tooltip: LocaleKeys.markUncompleted.tr(),
          onPressed: () => tasksCubit.updateTask(task.copyWith(completed: false)),
        ),
        title: Text(
          task.title,
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
          ),
        ),
        trailing: Visibility(
          visible: isHovered,
          child: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: LocaleKeys.deleteTask.tr(),
            onPressed: () => tasksCubit.deleteTask(task),
          ),
        ),
      ),
    );
  }
}
