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

        bool hasChildTasks = state.activeList!.items
            .where((element) => element.parent == task.id && !element.deleted)
            .isNotEmpty;

        Widget leadingWidget;
        if (hasChildTasks) {
          leadingWidget = IconButton(
            icon: Icon(
              expanded ? Icons.arrow_drop_down : Icons.arrow_right,
            ),
            onPressed: () => setState(() {
              expanded = !expanded;
            }),
          );
        } else {
          leadingWidget = Checkbox(
            value: task.completed,
            onChanged: (bool? value) => tasksCubit.updateTask(
              task.copyWith(completed: value),
            ),
          );
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
              children: [
                leadingWidget,
                Flexible(child: Text(task.title, style: titleTextStyle)),
              ],
            ),
          ),
        );

        Widget? subtitle;
        if (hasChildTasks) {
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
                            .map((e) => TaskTile(task: e))
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
            subtitle = Padding(
              padding: const EdgeInsets.only(left: 37),
              child: Text(task.description!),
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
