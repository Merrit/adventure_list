import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../tasks.dart';

class TaskTile extends StatefulWidget {
  final Task task;

  const TaskTile({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  bool expanded = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final Task task = state.activeList!.items.singleWhere(
          (element) => element.id == widget.task.id,
        );

        Future<void> _setActiveTaskCallback() async {
          String? taskId = (tasksCubit.state.activeTask == task) //
              ? null
              : task.id;
          tasksCubit.setActiveTask(taskId);

          if (platformIsMobile()) {
            await Navigator.pushNamed(
              context,
              TaskDetails.routeName,
            );

            // User has returned from details page, unset active task.
            tasksCubit.setActiveTask('');
          }
        }

        final List<Task> childTasks = state.activeList!.items
            .where((element) => element.parent == task.id && !element.deleted)
            .toList();

        bool hasChildTasks = childTasks.isNotEmpty;

        Widget leadingWidget;
        if (hasChildTasks && task.parent == null) {
          leadingWidget = IconButton(
            icon: Icon(
              expanded ? Icons.arrow_drop_down : Icons.arrow_right,
            ),
            onPressed: () => setState(() {
              expanded = !expanded;
            }),
          );
        } else if (hasChildTasks && task.parent != null) {
          leadingWidget = const SizedBox();
        } else {
          leadingWidget = Checkbox(
            value: task.completed,
            onChanged: (bool? value) => tasksCubit.updateTask(
              task.copyWith(completed: value),
            ),
          );
        }

        Widget tasksCompletedCountWidget;
        if (hasChildTasks) {
          final completedTasks =
              childTasks.where((element) => element.completed).length;
          tasksCompletedCountWidget = Padding(
            padding: const EdgeInsets.all(6.5),
            child: Text('($completedTasks/${childTasks.length})'),
          );
        } else {
          tasksCompletedCountWidget = const SizedBox();
        }

        TextStyle titleTextStyle = TextStyle(
          decoration: task.completed ? TextDecoration.lineThrough : null,
          fontSize: 18,
        );

        Widget titleRow = InkWell(
          onTap: () => _setActiveTaskCallback(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leadingWidget,
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // SizedBox ensures text aligns with top of checkbox.
                      const SizedBox(height: 4.5),
                      Flexible(child: Text(task.title, style: titleTextStyle)),
                    ],
                  ),
                ),
                tasksCompletedCountWidget,
              ],
            ),
          ),
        );

        Widget? subtitle;
        if (hasChildTasks && task.parent == null) {
          subtitle = Visibility(
            visible: expanded,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const VerticalDivider(thickness: 3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.description != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Text(task.description!),
                          ),
                        ...state.activeList!.items
                            .where((element) => element.parent == task.id)
                            .map((e) => Flexible(child: TaskTile(task: e)))
                            .toList()
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          if (task.description != null) {
            subtitle = Opacity(
              opacity: 0.7,
              child: Padding(
                padding: const EdgeInsets.only(left: 37),
                child: Text(task.description!),
              ),
            );
          }
        }

        final listTile = ListTile(
          title: titleRow,
          subtitle: subtitle,
        );

        return listTile;
      },
    );
  }
}
