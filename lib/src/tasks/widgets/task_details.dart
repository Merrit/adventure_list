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
    final mobileView = Scaffold(
      appBar: AppBar(),
      body: const TaskDetailsView(),
    );

    final Task? task = context.watch<TasksCubit>().state.activeTask;

    final largeScreenView = Expanded(
      flex: (task == null) ? 0 : 1,
      child: const TaskDetailsView(),
    );

    return (platformIsMobile()) ? mobileView : largeScreenView;
  }
}

class TaskDetailsView extends StatelessWidget {
  const TaskDetailsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final Task? task = state.activeTask;

        final widgetContents = Card(
          margin: const EdgeInsets.all(6),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: task == null
                  ? []
                  : [
                      Flexible(
                        fit: FlexFit.loose,
                        child: Row(
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
                                      onPressed: () {},
                                      child: const Text('menu item'),
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SizedBox(
                          width: 400,
                          child: ListView(
                            children: [
                              // Description
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: Text((task.description == null)
                                    ? 'Description'
                                    : task.description!),
                                onTap: () async {
                                  final String? newDescription =
                                      await showInputDialog(
                                    context: context,
                                  );

                                  if (newDescription == null) return;

                                  tasksCubit.updateTask(
                                    task.copyWith(description: newDescription),
                                  );
                                },
                              ),
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
                      ),
                    ],
            ),
          ),
        );

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) =>
              ScaleTransition(
            alignment: Alignment.centerLeft,
            scale: animation,
            child: child,
          ),
          child: (task == null) ? const SizedBox() : widgetContents,
        );
      },
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
