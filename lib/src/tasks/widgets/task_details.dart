import 'package:flutter/material.dart' hide PopupMenuButton, PopupMenuItem;
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
                        flex: 0,
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
                      const Flexible(
                        flex: 0,
                        child: Divider(),
                      ),
                      const SizedBox(height: 20),
                      Flexible(
                        child: ListView(
                          padding: const EdgeInsets.all(12.0),
                          controller: ScrollController(),
                          children: [
                            const _DescriptionWidget(),
                            const SizedBox(height: 20),
                            const Text('Sub-tasks'),
                            ...state.activeList!.items
                                .where((element) => element.parent == task.id)
                                .map((Task e) => ListTile(
                                      leading: Checkbox(
                                        onChanged: (value) {
                                          tasksCubit.updateTask(
                                            e.copyWith(completed: value),
                                          );
                                        },
                                        value: e.completed,
                                      ),
                                      title: Text(
                                        e.title,
                                        style: TextStyle(
                                          decoration: e.completed
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      onTap: () {
                                        tasksCubit.updateTask(
                                          e.copyWith(completed: !e.completed),
                                        );
                                      },
                                    ))
                                .toList(),
                            _AddSubTaskWidget(parentTask: task),
                          ],
                        ),
                      ),
                    ],
            ),
          ),
        );

        return AnimatedSwitcher(
          key: ValueKey(task),
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

class _DescriptionWidget extends StatefulWidget {
  const _DescriptionWidget({Key? key}) : super(key: key);

  @override
  State<_DescriptionWidget> createState() => _DescriptionWidgetState();
}

class _DescriptionWidgetState extends State<_DescriptionWidget> {
  @override
  void initState() {
    super.initState();
    final Task? task = tasksCubit.state.activeTask;
    if (task == null) return;

    controller.text = task.description ?? '';
    updatedDescription = task.description ?? '';

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setState(() {
          showControls = true;
          descriptionBorder = const OutlineInputBorder();
        });
      } else {
        setState(() {
          descriptionBorder = InputBorder.none;
        });
      }
    });
  }

  final controller = TextEditingController();
  final focusNode = FocusNode();
  InputBorder descriptionBorder = InputBorder.none;
  bool showControls = false;
  late String updatedDescription;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final task = state.activeTask;
        if (task == null) return const SizedBox();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                fillColor: Colors.transparent,
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    style: BorderStyle.none,
                  ),
                ),
                focusedBorder: Theme.of(context)
                    .inputDecorationTheme
                    .focusedBorder
                    ?.copyWith(),
                label: const Text('Description'),
              ),
              enableInteractiveSelection: true,
              focusNode: focusNode,
              maxLines: null,
              onChanged: (value) {
                controller.text = value;
                updatedDescription = value;
              },
            ),
            const SizedBox(height: 5),
            if (showControls)
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() => showControls = false);
                        controller.text = task.description ?? '';
                        updatedDescription = task.description ?? '';
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        tasksCubit.updateTask(
                          task.copyWith(description: updatedDescription),
                        );
                        setState(() => showControls = false);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AddSubTaskWidget extends StatelessWidget {
  final Task parentTask;

  const _AddSubTaskWidget({
    Key? key,
    required this.parentTask,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextInputListTile(
      placeholderText: 'Add sub-task',
      leading: const Icon(Icons.add),
      callback: (String value) {
        tasksCubit.createTask(
          Task(
            title: value,
            parent: parentTask.id,
          ),
        );
      },
      retainFocus: true,
    );
  }
}
