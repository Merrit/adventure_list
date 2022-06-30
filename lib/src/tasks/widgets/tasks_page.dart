import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../tasks.dart';
import 'task_details.dart';

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
            appBar: platformIsMobile() ? const _TaskListAppBar() : null,
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
                const TaskView(),
                const TaskDetails(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TaskListAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final preferredSize = const Size.fromHeight(kToolbarHeight);

  const _TaskListAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state.activeList == null) return AppBar();

        final TaskList activeList = state.activeList!;

        return AppBar(
          title: Text(activeList.title),
        );
      },
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
                      onTap: () {
                        tasksCubit.setActiveList(e.id);
                        if (platformIsMobile()) Navigator.pop(context);
                      },
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class TaskView extends StatelessWidget {
  const TaskView({Key? key}) : super(key: key);

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

class TaskListSettingsPage extends StatelessWidget {
  const TaskListSettingsPage({Key? key}) : super(key: key);

  static const routeName = 'task_list_settings_page';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: TextButton(
          onPressed: () async {
            await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: const Text(
                    'This will permanently delete this list. Are you sure?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () {
                        tasksCubit.deleteList();
                        Navigator.pushReplacementNamed(
                          context,
                          TasksPage.routeName,
                        );
                      },
                      child: const Text('CONFIRM'),
                    )
                  ],
                );
              },
            );

            // pop to root
          },
          child: const Text(
            'Delete List',
            style: TextStyle(color: Colors.red),
          ),
        ),
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
      onTap: () => tasksCubit.setActiveTask(task.id),
    );
  }
}
