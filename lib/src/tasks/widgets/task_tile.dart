import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:helpers/helpers.dart';

import '../../core/helpers/helpers.dart';
import '../tasks.dart';
import 'task_details/task_details.dart';

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
            isExpanded: false,
            isHovered: false,
            isSelected: isSelected,
            task: task,
          ),
        );

  void updateIsExpanded(bool value) {
    emit(state.copyWith(isExpanded: value));
  }

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
    required bool isExpanded,
    required bool isHovered,
    required bool isSelected,
    required Task task,
  }) = _TaskTileState;
}

class TaskTile extends StatelessWidget {
  final int index;
  final Task task;

  const TaskTile({
    required super.key,
    required this.index,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final tasksCubit = context.read<TasksCubit>();

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, tasksState) {
        final TaskList? activeList = tasksState.activeList;

        if (activeList == null) return const SizedBox();

        final tasks = activeList.items;
        final subTasks = tasks.subtasksOf(task.id);

        return BlocProvider(
          create: (context) => TaskTileCubit(
            index,
            task,
            childTasks: subTasks,
            isSelected: tasksState.activeTask?.id == task.id,
          ),
          child: Builder(
            builder: (context) {
              final stateCubit = context.read<TaskTileCubit>();
              final bool selected = tasksState.activeTask?.id == task.id;

              return BlocBuilder<TaskTileCubit, TaskTileState>(
                builder: (context, tileState) {
                  return Card(
                    margin: const EdgeInsets.all(0),
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
  late final TasksCubit tasksCubit;
  late final TaskTileCubit taskTileCubit;

  @override
  void initState() {
    super.initState();
    taskId = context.read<TaskTileCubit>().state.task.id;
    tasksCubit = context.read<TasksCubit>();
    taskTileCubit = context.read<TaskTileCubit>();
  }

  final expansionTileController = ExpansionTileController();

  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final expansionTileCloser = BlocListener<TasksCubit, TasksState>(
      listenWhen: (previous, current) =>
          previous.activeTask?.id == taskId && current.activeTask?.id != taskId,
      listener: (context, state) {
        final controller = ExpansionTileController.of(context);
        if (controller.isExpanded) {
          controller.collapse();
          taskTileCubit.updateIsExpanded(false);
        }
      },
      child: const SizedBox(),
    );

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, tasksState) {
        final bool selected = tasksState.activeTask?.id == taskId;

        return BlocBuilder<TaskTileCubit, TaskTileState>(
          builder: (context, taskTileState) {
            Widget? subtitle;
            if (taskTileState.task.dueDate != null || taskTileState.hasChildTasks) {
              final children = <Widget>[
                if (!expanded) const _DueDateChip(),
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

            final Widget contextMenuButton = (selected && !mediaQuery.isSmallScreen)
                ? const ContextMenuButton()
                : const SizedBox();

            final expansionTile = ExpansionTile(
              tilePadding: const EdgeInsets.all(0),
              collapsedBackgroundColor: Colors.transparent,
              controller: expansionTileController,
              initiallyExpanded: taskTileState.isSelected,
              onExpansionChanged: (bool isExpanded) {
                setState(() => expanded = isExpanded);

                if (isExpanded) {
                  tasksCubit.setActiveTask(taskTileState.task.id);
                  taskTileCubit.updateIsExpanded(true);
                } else {
                  taskTileCubit.updateIsExpanded(false);
                  final activeTask = context.read<TasksCubit>().state.activeTask;
                  // If the task is collapsed, set the active task to null.
                  //
                  // If the task collapsed because another task was expanded,
                  // allow that task to become the active task.
                  if (activeTask?.id == taskTileState.task.id) {
                    tasksCubit.setActiveTask(null);
                  }
                }
              },
              title: const _TitleRow(),
              subtitle: subtitle,
              trailing: contextMenuButton,
              children: [
                expansionTileCloser,
                const DueDateWidget(),
                const DueTimeWidget(),
                const RecurrenceWidget(),
                const DescriptionWidget(),
                const ParentSelectionWidget(),
                const SubTasksListWidget(),
                AddSubTaskWidget(parentTask: taskTileState.task),
              ],
            );

            final listTile = ListTile(
              title: const _TitleRow(),
              subtitle: subtitle,
              onTap: () => tasksCubit.setActiveTask(taskTileState.task.id),
            );

            return (MediaQuery.of(context).isSmallScreen) ? listTile : expansionTile;
          },
        );
      },
    );
  }
}

/// Row of widgets that make up the task tile.
///
/// Contains the Checkbox and task title.
///
/// This widget is wrapped in an [AnimatedDefaultTextStyle] to animate the
/// text style when the task is completed.
class _TitleRow extends StatefulWidget {
  const _TitleRow();

  @override
  State<_TitleRow> createState() => _TitleRowState();
}

class _TitleRowState extends State<_TitleRow> {
  late final TasksCubit tasksCubit;

  @override
  void initState() {
    super.initState();
    tasksCubit = context.read<TasksCubit>();
  }

  /// The duration of the animation when the task is completed.
  final int animationDuration = 1200;

  /// Indicates the task has been completed via setState, because if we rely on
  /// the value from the cubit the task will be moved to the completed list
  /// before the animation completes.
  bool? animationCompleted;

  /// The text style to use when the task is completed.
  TextStyle? animationTextStyle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, tasksState) {
        return BlocBuilder<TaskTileCubit, TaskTileState>(
          builder: (context, tileState) {
            final TextStyle titleTextStyle = animationTextStyle ??
                Theme.of(context).textTheme.titleMedium!.copyWith(
                      decoration:
                          tileState.task.completed ? TextDecoration.lineThrough : null,
                    );

            final bool completed = animationCompleted ?? tileState.task.completed;

            final Widget collapsedTitle = Text(tileState.task.title);

            final Widget expandedTitle = TextField(
              controller: TextEditingController(text: tileState.task.title),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (value) => tasksCubit.updateTask(
                tileState.task.copyWith(title: value),
              ),
            );

            final Widget checkbox = SizedBox(
              // SizedBox removes the padding from the Checkbox so that it aligns
              // with the children of the ExpansionTile.
              height: 24,
              width: 24,
              child: Checkbox(
                value: completed,
                onChanged: (bool? completed) {
                  if (completed == null) return;

                  if (completed) {
                    setState(() {
                      animationCompleted = true;

                      animationTextStyle = titleTextStyle.copyWith(
                        decoration: TextDecoration.lineThrough,
                        fontStyle: FontStyle.italic,
                      );
                    });
                  }

                  final int? delay = completed ? animationDuration : null;

                  setTaskCompleted(
                    context: context,
                    delay: delay,
                    tasksCubit: context.read<TasksCubit>(),
                    task: tileState.task,
                    completed: completed,
                  );
                },
              ),
            );

            final Widget titleWidget =
                (tileState.isExpanded) ? expandedTitle : collapsedTitle;

            return ReorderableDragStartListener(
              index: tileState.index,
              // Disable for sub-tasks until reordering them is implemented.
              enabled: tileState.task.parent == null,
              child: AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: animationDuration),
                style: titleTextStyle,
                child: ListTile(
                  leading: checkbox,
                  title: titleWidget,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Displays a chip indicating when the task is due.
class _DueDateChip extends StatelessWidget {
  const _DueDateChip();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskTileCubit, TaskTileState>(
      builder: (context, tileState) {
        final task = tileState.task;
        if (task.dueDate == null) return const SizedBox();

        final color = task.isOverdue ? Theme.of(context).colorScheme.error : null;

        return Chip(
          label: Text(
            task.dueDate!.toLocal().toDueDateLabel(),
            style: TextStyle(
              color: color,
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
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final taskId = context.read<TaskTileCubit>().state.task.id;
        final Task? task = state.activeList?.items.getTaskById(taskId);
        if (task == null) return const SizedBox();

        final childTasks = state.activeList!.items.subtasksOf(task.id);
        if (childTasks.isEmpty) return const SizedBox();

        final completedTasks = childTasks.where((element) => element.completed);

        return Chip(
          label: Text(
            '${completedTasks.length}/${childTasks.length}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }
}

/// Set the completed status of [task] to [completed].
///
/// If [completed] is true, a snackbar will be displayed with an undo button.
///
/// If [delay] is not null, the action will be delay by [delay] milliseconds to allow
/// animations to complete before the task is updated.
Future<void> setTaskCompleted({
  required BuildContext context,
  int? delay,
  required TasksCubit tasksCubit,
  required Task task,
  required bool completed,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  if (delay != null) {
    await Future.delayed(Duration(milliseconds: delay));
  }

  scaffoldMessenger.hideCurrentSnackBar();

  final command = SetTaskCompletedCommand(
    cubit: tasksCubit,
    task: task,
    completed: completed,
  );

  command.execute();

  if (!completed) return;

  if (tasksCubit.state.activeTask?.id == task.id) {
    tasksCubit.setActiveTask(null);
  }

  scaffoldMessenger.showSnackBar(
    SnackBar(
      content: const Text('Task completed'),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => command.undo(),
      ),
    ),
  );
}
