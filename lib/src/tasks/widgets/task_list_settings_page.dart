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
      body: const TaskListSettingsView(),
    );
  }
}

class TaskListSettingsView extends StatelessWidget {
  const TaskListSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final taskList = state.activeList;

        if (taskList == null) {
          return const SizedBox();
        }

        return Center(
          child: Column(
            children: [
              Card(
                child: ListTile(
                  leading: const Text('List Name'),
                  title: Align(
                    alignment: Alignment.centerRight,
                    child: Text(taskList.title),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    String? newName = await showInputDialog(
                      context: context,
                    );

                    if (newName == null || newName == '') return;

                    tasksCubit.updateList(
                      taskList.copyWith(title: newName),
                    );
                  },
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);

                  final bool? deleted = await showDialog(
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
                              Navigator.pop(context, true);
                            },
                            child: const Text('CONFIRM'),
                          )
                        ],
                      );
                    },
                  );

                  if (deleted == true) {
                    navigator.pushReplacementNamed(TasksPage.routeName);
                  }
                },
                child: const Text(
                  'Delete List',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
