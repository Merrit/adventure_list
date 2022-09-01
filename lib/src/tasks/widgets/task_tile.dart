import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../../core/core.dart';
import '../tasks.dart';

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

class TaskTileState extends Equatable {
  final List<Task> childTasks;
  final bool hasChildTasks;
  final int index;
  final bool isHovered;
  final Task task;

  const TaskTileState({
    required this.childTasks,
    required this.hasChildTasks,
    required this.index,
    required this.isHovered,
    required this.task,
  });

  @override
  List<Object> get props {
    return [
      childTasks,
      hasChildTasks,
      index,
      isHovered,
      task,
    ];
  }

  TaskTileState copyWith({
    List<Task>? childTasks,
    bool? hasChildTasks,
    int? index,
    bool? isHovered,
    Task? task,
  }) {
    return TaskTileState(
      childTasks: childTasks ?? this.childTasks,
      hasChildTasks: hasChildTasks ?? this.hasChildTasks,
      index: index ?? this.index,
      isHovered: isHovered ?? this.isHovered,
      task: task ?? this.task,
    );
  }
}

class TaskTile extends StatelessWidget {
  final int index;
  final Task task;

  const TaskTile({
    Key? key,
    required this.index,
    required this.task,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final TaskList? activeList = state.activeList;

        if (activeList == null) return const SizedBox();

        final childTasks = state.activeList!.items
            .where((element) => element.parent == task.id && !element.deleted)
            .toList();

        final completedTasks = childTasks //
            .where((element) => element.completed)
            .length;

        Future<void> setActiveTaskCallback() async {
          String? taskId = (tasksCubit.state.activeTask == task) //
              ? null
              : task.id;
          tasksCubit.setActiveTask(taskId);

          if (platformIsMobile()) {
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
    // final stateCubit = context.read<TaskTileCubit>();

    return BlocBuilder<TaskTileCubit, TaskTileState>(
      builder: (context, state) {
        TextStyle titleTextStyle = TextStyle(
          decoration: state.task.completed ? TextDecoration.lineThrough : null,
        );

        Widget dragHandle;
        if (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) {
          dragHandle = const SizedBox();
        } else {
          dragHandle = Opacity(
            opacity: state.isHovered ? 0.5 : 0.0,
            child: state.task.parent == null
                // Disable for sub-tasks until reordering them is implemented.
                ? ReorderableDragStartListener(
                    index: state.index,
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
              value: state.task.completed,
              onChanged: (bool? value) => tasksCubit.updateTask(
                state.task.copyWith(completed: value),
              ),
              shape: roundedSquareBorder,
            ),
            Flexible(
              child: Text(
                state.task.title,
                style: titleTextStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}
