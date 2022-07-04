import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/core.dart';
import '../tasks.dart';

class TaskListSettingsPage extends StatelessWidget {
  const TaskListSettingsPage({Key? key}) : super(key: key);

  static const routeName = 'task_list_settings_page';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          if (state.activeList == null) Navigator.pop(context);

          final taskList = state.activeList;

          if (taskList == null) {
            Navigator.pop(context);
            return const SizedBox();
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      title: const Text('List Name'),
                      subtitle: Text(taskList.title),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () async {
                        String? newName = await showInputDialog(
                          context: context,
                        );

                        if (newName == null) return;

                        tasksCubit.updateList(
                          taskList.copyWith(title: newName),
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: const Text(
                              'This will permanently delete this list. Are you sure?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('CANCEL'),
                              ),
                              TextButton(
                                onPressed: () {
                                  tasksCubit.deleteList();
                                  Navigator.pushReplacementNamed(
                                    context,
                                    TasksPage.routeName,
                                  );
                                },
                                child: const Text('CONFIRM'),
                              )
                            ],
                          );
                        },
                      );

                      // pop to root
                    },
                    child: const Text(
                      'Delete List',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
