import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../settings/settings.dart';
import '../../tasks/tasks.dart';
import '../home_widget.dart';

class HomeWidgetConfigPage extends StatelessWidget {
  static const routeName = '/home_widget_config_page';

  const HomeWidgetConfigPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configure Home Widget')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return BlocBuilder<TasksCubit, TasksState>(
            builder: (context, tasksState) {
              return ListView(
                children: [
                  const ListTile(
                    title: Text('List to display'),
                  ),
                  ...tasksState.taskLists
                      .map((e) => RadioListTile(
                            value: e.id,
                            groupValue: settingsState.homeWidgetSelectedListId,
                            onChanged: (String? value) async {
                              if (value == null) return;

                              context
                                  .read<SettingsCubit>()
                                  .updateHomeWidgetSelectedListId(value);

                              TaskList selectedList = tasksState //
                                  .taskLists
                                  .singleWhere(
                                (taskList) => taskList.id == value,
                              );

                              final selectedListItems = selectedList.items
                                  .where(
                                      (e) => !e.completed && e.parent == null)
                                  .toList();

                              selectedList = selectedList.copyWith(
                                items: selectedListItems,
                              );

                              await context
                                  .read<HomeWidgetManager>()
                                  .updateHomeWidget(
                                    'selectedList',
                                    selectedList.toJson(),
                                  );
                            },
                            title: Text(e.title),
                          ))
                      .toList(),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final navigator = Navigator.of(context);
          // Disable move to back while the widget doesn't have a dedicated
          // config button.
          // await MoveToBackground.moveTaskToBack();
          navigator.pop();
        },
        label: const Text('Done'),
      ),
    );
  }
}
