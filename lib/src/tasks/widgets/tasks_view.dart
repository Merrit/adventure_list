import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../tasks.dart';

class TasksView extends StatelessWidget {
  const TasksView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          if (state.activeList == null) return const SizedBox();

          return SizedBox(
            width: platformIsMobile() ? null : 500,
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        final textFieldController = TextEditingController();
                        String? newTaskTitle;

                        await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: TextField(
                                controller: textFieldController,
                                onSubmitted: (String value) {
                                  newTaskTitle = value;
                                  Navigator.pop(context);
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    newTaskTitle = textFieldController.text;
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('CANCEL'),
                                ),
                              ],
                            );
                          },
                        );

                        if (newTaskTitle == null) return;

                        tasksCubit.createTask(
                          Task(title: textFieldController.text),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        TaskListSettingsPage.routeName,
                      ),
                    )
                  ],
                ),
                Expanded(
                  child: ReorderableListView(
                    scrollController: ScrollController(),
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) {},
                    children: state.activeList!.items
                        .where((element) => element.parent == null)
                        .map((e) => TaskTile(key: ValueKey(e), task: e))
                        .toList(),
                  ),
                ),
                if (state.activeList!.items.any((element) => element.completed))
                  ExpansionTile(
                    title: const Text('Completed'),
                    children: state.activeList!.items
                        .where((element) => element.completed)
                        .map((e) => TaskTile(task: e))
                        .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
