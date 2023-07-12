import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../tasks.dart';

class SubTasks extends StatelessWidget {
  const SubTasks({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final activeList = state.activeList;
        final parentTask = state.activeTask;

        if (activeList == null || parentTask == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...activeList.items
                .subtasksOf(parentTask.id)
                .map((e) => TaskTile(key: ValueKey(e), index: 0, task: e))
                .toList(),
          ],
        );
      },
    );
  }
}
