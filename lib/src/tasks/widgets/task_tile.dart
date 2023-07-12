import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/helpers/helpers.dart';
import '../tasks.dart';
import 'task_details/sub_tasks.dart';

part 'task_tile.freezed.dart';

class TaskTileCubit extends Cubit<TaskTileState> {
  TaskTileCubit(
    int index,
    Task task, {
    required List<Task> childTasks,
    required bool isSelected,
  }) : super(
          TaskTileState(
            childTasks: childTasks,
            hasChildTasks: childTasks.isNotEmpty,
            index: index,
            isHovered: false,
            isSelected: isSelected,
            task: task,
          ),
        );

  void updateIsHovered(bool value) {
    emit(state.copyWith(isHovered: value));
  }

  void updateIsSelected(bool value) {
    emit(state.copyWith(isSelected: value));
  }
}

@freezed
class TaskTileState with _$TaskTileState {
  const factory TaskTileState({
    required List<Task> childTasks,
    required bool hasChildTasks,
    required int index,
    required bool isHovered,
    required bool isSelected,
    required Task task,
  }) = _TaskTileState;
}

class TaskTile extends StatelessWidget {
  final int index;
  final Task task;

  const TaskTile({
    required Key? key,
    required this.index,
    required this.task,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, tasksState) {
        final TaskList? activeList = tasksState.activeList;

        if (activeList == null) return const SizedBox();

        final childTasks = tasksState.activeList!.items.subtasksOf(task.id);

        return BlocProvider(
          create: (context) => TaskTileCubit(
            index,
            task,
            childTasks: childTasks,
            isSelected: tasksState.activeTask?.id == task.id,
          ),
          child: Builder(
            builder: (context) {
              final stateCubit = context.read<TaskTileCubit>();
              final bool selected = tasksState.activeTask?.id == task.id;

              return BlocBuilder<TaskTileCubit, TaskTileState>(
                builder: (context, tileState) {
                  return Card(
                    elevation: (tileState.isHovered || selected) ? 1 : 0,
                    child: InkWell(
                      hoverColor: Colors.transparent,
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onTap: () => tasksCubit.setActiveTask(task.id),
                      child: MouseRegion(
                        onEnter: (_) => stateCubit.updateIsHovered(true),
                        onExit: (_) => stateCubit.updateIsHovered(false),
                        child: const _TaskTileContents(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _TaskTileContents extends StatefulWidget {
  const _TaskTileContents();

  @override
  State<_TaskTileContents> createState() => _TaskTileContentsState();
}

class _TaskTileContentsState extends State<_TaskTileContents> {
  late String taskId;

  @override
  void initState() {
    super.initState();
    taskId = context.read<TaskTileCubit>().state.task.id;
  }

  final expansionTileController = ExpansionTileController();

  @override
  Widget build(BuildContext context) {
    final expansionTileCloser = BlocListener<TasksCubit, TasksState>(
      listenWhen: (previous, current) =>
          previous.activeTask?.id == taskId && current.activeTask?.id != taskId,
      listener: (context, state) {
        final controller = ExpansionTileController.of(context);
        if (controller.isExpanded) controller.collapse();
      },
      child: const SizedBox(),
    );

    return BlocBuilder<TaskTileCubit, TaskTileState>(
      builder: (context, state) {
        Widget? subtitle;
        if (state.task.isOverdue || state.hasChildTasks) {
          final children = <Widget>[
            const _OverdueIndicator(),
            const _ChildTasksIndicator(),
          ];

          subtitle = Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: children,
            ),
          );
        }

        final expansionTile = ExpansionTile(
          controller: expansionTileController,
          initiallyExpanded: state.isSelected,
          onExpansionChanged: (value) {
            if (value) {
              tasksCubit.setActiveTask(state.task.id);
            } else {
              final activeTask = context.read<TasksCubit>().state.activeTask;
              // If the task is collapsed, set the active task to null.
              //
              // If the task collapsed because another task was expanded,
              // allow that task to become the active task.
              if (activeTask?.id == state.task.id) {
                tasksCubit.setActiveTask(null);
              }
            }
          },
          title: const _TitleRow(),
          subtitle: subtitle,
          trailing: const SizedBox(),
          children: [
            expansionTileCloser,
            const DueDateWidget(),
            const DueTimeWidget(),
            const DescriptionWidget(),
            const ParentSelectionWidget(),
            const SubTasks(),
            AddSubTaskWidget(parentTask: state.task),
          ],
        );

        final listTile = ListTile(
          title: const _TitleRow(),
          subtitle: subtitle,
          onTap: () => tasksCubit.setActiveTask(state.task.id),
        );

        return (MediaQuery.of(context).isSmallScreen)
            ? listTile
            : expansionTile;
      },
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, tasksState) {
        return BlocBuilder<TaskTileCubit, TaskTileState>(
          builder: (context, tileState) {
            final bool selected =
                tasksState.activeTask?.id == tileState.task.id;
            final TextStyle titleTextStyle = TextStyle(
              decoration:
                  tileState.task.completed ? TextDecoration.lineThrough : null,
              color: selected ? Theme.of(context).colorScheme.primary : null,
            );

            Widget dragHandle;
            if (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS) {
              dragHandle = const SizedBox();
            } else {
              dragHandle = Opacity(
                opacity: tileState.isHovered ? 0.5 : 0.0,
                child: tileState.task.parent == null
                    // Disable for sub-tasks until reordering them is implemented.
                    ? ReorderableDragStartListener(
                        index: tileState.index,
                        child: const Icon(Icons.drag_indicator),
                      )
                    : const Icon(
                        Icons.hot_tub,
                        color: Colors.transparent,
                      ),
              );
            }

            return Row(
              children: [
                dragHandle,
                Checkbox(
                  value: tileState.task.completed,
                  onChanged: (bool? value) => tasksCubit.setTaskCompleted(
                    tileState.task.id,
                    value!,
                  ),
                ),
                Flexible(
                  child: Text(
                    tileState.task.title,
                    style: titleTextStyle,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Displays an "Overdue" label if the task is overdue.
class _OverdueIndicator extends StatelessWidget {
  const _OverdueIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskTileCubit, TaskTileState>(
      builder: (context, tileState) {
        final task = tileState.task;
        if (!task.isOverdue) return const SizedBox();

        return Chip(
          label: Text(
            'Overdue',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        );
      },
    );
  }
}

class _ChildTasksIndicator extends StatelessWidget {
  const _ChildTasksIndicator();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskTileCubit, TaskTileState>(
      builder: (context, tileState) {
        final childTasks = tileState.childTasks;
        if (childTasks.isEmpty) return const SizedBox();

        final completedTasks = childTasks //
            .where((element) => element.completed)
            .length;

        return Chip(
          label: Text(
            '$completedTasks/${childTasks.length}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }
}
