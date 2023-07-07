import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generated/locale_keys.g.dart';
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
                  leading: Text(LocaleKeys.listSettings_listName.tr()),
                  title: Align(
                    alignment: Alignment.centerRight,
                    child: Text(taskList.title),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final String? newName = await showInputDialog(
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
                        content: Text(
                          LocaleKeys.listSettings_confirmDelete.tr(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(LocaleKeys.cancel.tr()),
                          ),
                          TextButton(
                            onPressed: () {
                              tasksCubit.deleteList();
                              Navigator.pop(context, true);
                            },
                            child: Text(
                              LocaleKeys.confirm.tr(),
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        ],
                      );
                    },
                  );

                  if (deleted == true) {
                    navigator.pushReplacementNamed(TasksPage.routeName);
                  }
                },
                child: Text(
                  LocaleKeys.listSettings_deleteList.tr(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
