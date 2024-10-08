import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generated/locale_keys.g.dart';
import '../../settings/settings.dart';
import '../../tasks/tasks.dart';
import '../home_widget.dart';

class HomeWidgetConfigPage extends StatelessWidget {
  static const routeName = '/home_widget_config_page';

  const HomeWidgetConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.homeWidgetConfig_title.tr())),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return BlocBuilder<TasksCubit, TasksState>(
            builder: (context, tasksState) {
              return ListView(
                children: [
                  ListTile(
                    title: Text(LocaleKeys.homeWidgetConfig_listToDisplay.tr()),
                  ),
                  ...tasksState.taskLists.map((e) => RadioListTile(
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
                              .where((e) => !e.completed && e.parent == null)
                              .toList();

                          selectedList = selectedList.copyWith(
                            items: selectedListItems,
                          );

                          await context.read<HomeWidgetManager>().updateHomeWidget(
                                'selectedList',
                                jsonEncode(selectedList.toJson()),
                              );
                        },
                        title: Text(e.title),
                      )),
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
