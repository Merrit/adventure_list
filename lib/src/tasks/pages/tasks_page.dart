import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../tasks.dart';

class TasksPage extends StatelessWidget {
  static const routeName = '/';

  const TasksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Scaffold(
            appBar: platformIsMobile() ? AppBar() : null,
            drawer: platformIsMobile()
                ? Drawer(
                    child: Column(
                      children: const [
                        CreateListButton(),
                        ScrollingListTiles(),
                      ],
                    ),
                  )
                : null,
            body: Row(
              children: [
                if (!platformIsMobile()) const NavigationBar(),
                const TaskListView(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class NavigationBar extends StatelessWidget {
  const NavigationBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        // Currently a ListView because NavigationRail doesn't allow
        // having fewer than 2 items.
        // https://github.com/flutter/flutter/pull/104914
        return SizedBox(
          width: 250,
          child: Card(
            child: Column(
              children: const [
                CreateListButton(),
                ScrollingListTiles(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CreateListButton extends StatelessWidget {
  const CreateListButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add),
      onPressed: () async {
        final textFieldController = TextEditingController();

        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: TextField(
                controller: textFieldController,
                onSubmitted: (_) => Navigator.pop(context),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
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

        if (textFieldController.value.text == '') return;

        tasksCubit.createList(textFieldController.text);
      },
    );
  }
}

class ScrollingListTiles extends StatelessWidget {
  const ScrollingListTiles({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          return ListView(
            children: state.taskLists
                .map((e) => ListTile(
                      title: Text(e.title),
                      selected: (state.activeList == e),
                      onTap: () => tasksCubit.setActiveList(e.id),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class TaskListView extends StatelessWidget {
  const TaskListView({Key? key}) : super(key: key);

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
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final textFieldController = TextEditingController();

                    await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: TextField(
                            controller: textFieldController,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
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

                    tasksCubit.createTask(
                      Task(title: textFieldController.text),
                    );
                  },
                ),
                Expanded(
                  child: ReorderableListView(
                    scrollController: ScrollController(),
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) {},
                    children: state.activeList!.items
                        .where((element) => !element.completed)
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

class TaskTile extends StatelessWidget {
  final Task task;

  const TaskTile({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle titleTextStyle = TextStyle(
      decoration: task.completed ? TextDecoration.lineThrough : null,
      fontSize: 18,
    );

    Widget? subtitle;
    if (task.description != null) subtitle = Text(task.description!);

    return ListTile(
      title: Text(task.title, style: titleTextStyle),
      leading: Checkbox(
        value: task.completed,
        onChanged: (bool? value) => tasksCubit.updateTask(
          task.copyWith(completed: value),
        ),
      ),
      // subtitle: subtitle,
      subtitle: subtitle,
      onTap: () {},
    );
  }
}
