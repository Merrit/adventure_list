import 'package:flutter/material.dart' hide PopupMenuButton, PopupMenuItem;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../../../core/core.dart';
import '../../tasks.dart';

class TaskDetailsHeader extends StatelessWidget {
  const TaskDetailsHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => tasksCubit.setActiveTask(null),
            ),
            const Flexible(child: _TaskNameWidget()),
            PopupMenuButton(
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    child: TextButton(
                      onPressed: () {
                        final task = tasksCubit.state.activeTask;
                        if (task == null) return;

                        tasksCubit.clearCompletedTasks(task.id);
                        Navigator.pop(context);
                      },
                      child: const Text('Clear completed sub-tasks'),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _TaskNameWidget extends StatelessWidget {
  const _TaskNameWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state.activeTask == null) return const SizedBox();

        return TextInputListTile(
          key: ValueKey(state.activeTask),
          placeholderText: state.activeTask!.title,
          editingPlaceholderText: true,
          textAlign: TextAlign.center,
          unfocusedOpacity: 1.0,
          callback: (String value) => tasksCubit.updateTask(
            state.activeTask!.copyWith(
              title: value,
            ),
          ),
        );
      },
    );
  }
}
