import 'package:flutter/foundation.dart';
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
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(DiagnosticsProperty<bool>('expanded', expanded));
  }

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
                Opacity(
                  opacity: 0.6,
                  child: IconButton(
                    icon: Icon(
                      expanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                    ),
                    disabledColor: Colors.transparent,
                    onPressed: hasChildTasks
                        ? () => setState(() {
                              expanded = !expanded;
                            })
                        : null,
                  ),
                ),
                Checkbox(
                  value: task.completed,
                  onChanged: (bool? value) => tasksCubit.updateTask(
                    task.copyWith(completed: value),
                  ),
                ),
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
                            .where((element) =>
                                (element.parent == task.id) && !element.deleted)
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
