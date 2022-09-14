import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:move_to_background/move_to_background.dart';

import '../../settings/settings.dart';
import '../../tasks/tasks.dart';
import '../home_widget.dart';

class HomeWidgetConfigPage extends StatelessWidget {
  static const routeName = '/home_widget_config_page';

  const HomeWidgetConfigPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        // Ensure the back button goes to the main screen.
        Navigator.pushReplacementNamed(context, TasksPage.routeName);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Configure Home Widget')),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            return BlocBuilder<TasksCubit, TasksState>(
              builder: (context, tasksState) {
                return ListView(
                  children: [
                    ...tasksState.taskLists
                        .map((e) => RadioListTile(
                              value: e.id,
                              groupValue:
                                  settingsState.homeWidgetSelectedListId,
                              onChanged: (String? value) async {
                                if (value == null) return;

                                settingsCubit.updateHomeWidgetSelectedListId(
                                  value,
                                );

                                final selectedList = tasksState //
                                    .taskLists
                                    .singleWhere(
                                  (taskList) => taskList.id == value,
                                );

                                selectedList.items.removeWhere((e) =>
                                    e.completed ||
                                    e.deleted ||
                                    e.parent != null);

                                await updateHomeWidget(
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
            await MoveToBackground.moveTaskToBack();
            navigator.pushReplacementNamed(TasksPage.routeName);
          },
          // onPressed: () => SystemNavigator.pop(),
          label: const Text('Done'),
        ),
      ),
    );
  }
}
