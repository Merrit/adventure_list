import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../../core/core.dart';
import '../tasks.dart';

class TaskDetails extends StatelessWidget {
  static const routeName = 'task_details';

  const TaskDetails({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final Task? task = state.activeTask;

        return Expanded(
          child: Card(
            margin: const EdgeInsets.all(6),
            child: Column(
              children: task == null
                  ? []
                  : [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CircleButton(
                            onPressed: () => tasksCubit.setActiveTask(null),
                            child: const Icon(Icons.close),
                          ),
                          Text(task.title),
                          GestureDetector(
                            onTapUp: (details) {
                              showContextMenu(
                                context: context,
                                offset: details.globalPosition,
                                items: [
                                  PopupMenuItem(
                                    child: TextButton(
                                      onPressed: () {},
                                      child: const Text('label'),
                                    ),
                                  ),
                                ],
                              );
                            },
                            child: const CircleButton(
                              // onPressed: () {},
                              child: Icon(Icons.more_vert),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListView(
                          children: [
                            OutlinedButton(
                              onPressed: () async {
                                final newTaskName = await showInputDialog(
                                  context: context,
                                );

                                if (newTaskName == null) return;

                                tasksCubit.createTask(
                                  Task(
                                    title: newTaskName,
                                    parent: task.id,
                                  ),
                                );
                              },
                              child: const Text('Add subtask'),
                            ),
                            ...state.activeList!.items
                                .where((element) => element.parent == task.id)
                                .map((e) => ListTile(
                                      title: Text(e.title),
                                    ))
                                .toList()
                          ],
                        ),
                      ),
                    ],
            ),
          ),
        );
      },
    );
  }
}
