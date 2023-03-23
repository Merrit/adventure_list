import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/core.dart';
import '../../core/helpers/helpers.dart';
import '../tasks.dart';

part 'task_tile.freezed.dart';

class TaskTileCubit extends Cubit<TaskTileState> {
  TaskTileCubit(
    int index,
    Task task, {
    required List<Task> childTasks,
  }) : super(
          TaskTileState(
            childTasks: childTasks,
            hasChildTasks: childTasks.isNotEmpty,
            index: index,
            isHovered: false,
            task: task,
          ),
        );

  void updateIsHovered(bool value) {
    emit(state.copyWith(isHovered: value));
  }
}

@freezed
class TaskTileState with _$TaskTileState {
  const factory TaskTileState({
    required List<Task> childTasks,
    required bool hasChildTasks,
    required int index,
    required bool isHovered,
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
    final mediaQuery = MediaQuery.of(context);

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final TaskList? activeList = state.activeList;

        if (activeList == null) return const SizedBox();

        final childTasks = state.activeList!.items.subtasksOf(task.id);

        final completedTasks = childTasks //
            .where((element) => element.completed)
            .length;

        Future<void> setActiveTaskCallback() async {
          final String? taskId = (tasksCubit.state.activeTask == task) //
              ? null
              : task.id;
          tasksCubit.setActiveTask(taskId);

          if (mediaQuery.isSmallScreen) {
            await Navigator.pushNamed(
              context,
              TaskDetails.routeName,
            );

            // User has returned from details page, unset active task.
            tasksCubit.setActiveTask(null);
          }
        }

        return BlocProvider(
          create: (context) => TaskTileCubit(
            index,
            task,
            childTasks: childTasks,
          ),
          child: Builder(
            builder: (context) {
              final stateCubit = context.read<TaskTileCubit>();

              return InkWell(
                hoverColor: Colors.transparent,
                onTap: () => setActiveTaskCallback(),
                child: MouseRegion(
                  onEnter: (_) => stateCubit.updateIsHovered(true),
                  onExit: (_) => stateCubit.updateIsHovered(false),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _TitleRow(),
                      Padding(
                        padding: const EdgeInsets.only(left: 62),
                        child: Opacity(
                          opacity: 0.8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (childTasks.isNotEmpty)
                                Text('($completedTasks/${childTasks.length})'),
                              if (task.description != null)
                                Text(task.description!),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
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
                  onChanged: (bool? value) => tasksCubit.updateTask(
                    tileState.task.copyWith(completed: value!),
                  ),
                  shape: roundedSquareBorder,
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
