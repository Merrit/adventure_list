import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../tasks.dart';

/// Widget that shows the list of subtasks of the active task.
class SubTasksListWidget extends StatelessWidget {
  const SubTasksListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final activeList = state.activeList;
        final parentTask = state.activeTask;

        if (activeList == null || parentTask == null) {
          return const SizedBox.shrink();
        }

        final subtasks = activeList.items.subtasksOf(parentTask.id);

        if (subtasks.isEmpty) {
          return const SizedBox.shrink();
        }

        final Widget subtasksHeader = Padding(
          padding: const EdgeInsets.only(top: 16, left: 16),
          child: Text(
            LocaleKeys.subtasks_title.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        );

        return Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              subtasksHeader,

              /// Subtasks list
              ...subtasks.map((e) => _SubTaskWidget(e)),
            ],
          ),
        );
      },
    );
  }
}

/// Widget that shows a subtask.
class _SubTaskWidget extends StatelessWidget {
  final Task task;

  const _SubTaskWidget(this.task);

  @override
  Widget build(BuildContext context) {
    final tasksCubit = context.read<TasksCubit>();

    return ListTile(
      title: Text(task.title),
      leading: Checkbox(
        value: task.completed,
        onChanged: (value) {
          if (value == null) return;
          tasksCubit.updateTask(task.copyWith(completed: value));
        },
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () {
          tasksCubit.deleteTask(task);
        },
      ),
    );
  }
}
