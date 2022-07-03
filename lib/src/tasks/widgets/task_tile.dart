import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  late final Task task;

  @override
  void initState() {
    task = widget.task;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        TextStyle titleTextStyle = TextStyle(
          decoration: task.completed ? TextDecoration.lineThrough : null,
          fontSize: 18,
        );

        Widget title = Text(task.title, style: titleTextStyle);

        Widget checkbox = Checkbox(
          value: task.completed,
          onChanged: (bool? value) => tasksCubit.updateTask(
            task.copyWith(completed: value),
          ),
        );

        Widget? subtitle;
        if (task.description != null) {
          subtitle = Text(task.description!);
        }

        bool hasChildTasks = state.activeList!.items
            .where((element) => element.parent == task.id)
            .isNotEmpty;

        final expansionTile = ExpansionTile(
          controlAffinity: ListTileControlAffinity.leading,
          title: title,
          trailing: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => tasksCubit.setActiveTask(task.id),
          ),
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  const VerticalDivider(thickness: 3),
                  Expanded(
                    child: Column(
                      children: state.activeList!.items
                          .where((element) => element.parent == task.id)
                          .map(
                            (e) => TaskTile(task: e),
                            // (e) => ExpansionTile(title: Text(e.title)),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final listTile = ListTile(
          title: title,
          leading: checkbox,
          // trailing: ,
          subtitle: subtitle,
          onTap: () => tasksCubit.setActiveTask(task.id),
        );

        return hasChildTasks ? expansionTile : listTile;
      },
    );
  }
}
