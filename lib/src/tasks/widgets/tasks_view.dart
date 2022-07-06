import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../../core/core.dart';
import '../tasks.dart';

class TasksView extends StatelessWidget {
  const TasksView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state.activeList == null) return const SizedBox();

        return SizedBox(
          width: platformIsMobile() ? null : 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TasksHeader(),
              const NewTaskButton(),
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
    );
  }
}

class _TasksHeader extends StatelessWidget {
  const _TasksHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    TaskListSettingsPage.routeName,
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 60, bottom: 10),
              child: Text(
                state.activeList!.title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
