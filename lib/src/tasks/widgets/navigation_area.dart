import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../../app/cubit/app_cubit.dart';
import '../../core/core.dart';
import '../../settings/widgets/settings_page.dart';
import '../tasks.dart';

class CustomNavigationRail extends StatelessWidget {
  const CustomNavigationRail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        // Currently a ListView because NavigationRail doesn't allow
        // having fewer than 2 items.
        // https://github.com/flutter/flutter/pull/104914
        return const SizedBox(
          width: 250,
          child: Card(
            margin: EdgeInsets.all(6),
            child: _NavContents(),
          ),
        );
      },
    );
  }
}

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Drawer(
      child: _NavContents(),
    );
  }
}

class _NavContents extends StatelessWidget {
  const _NavContents({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _CreateListButton(),
        const _ScrollingListTiles(),
        ListTile(
          title: const Text('Settings'),
          onTap: () {
            if (platformIsMobile()) {
              Navigator.pushNamed(context, SettingsPage.routeName);
            } else {
              showDialog(
                context: context,
                builder: (context) => const SettingsDialog(),
              );
            }
          },
        ),
        const UpdateButton(),
      ],
    );
  }
}

class UpdateButton extends StatelessWidget {
  const UpdateButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) return const SizedBox();

    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        if (!state.updateAvailable) return const SizedBox();

        Widget child;
        if (state.updateInProgress) {
          child = Center(
            child: Transform.scale(
              scale: 0.8,
              child: CircularProgressIndicator(color: Colors.pink.shade400),
            ),
          );
        } else {
          final text = (state.updateDownloaded) ? 'RESTART' : 'DOWNLOAD UPDATE';
          child = Text(text);
        }

        return ListTile(
          title: ElevatedButton(
            onPressed: () => (state.updateDownloaded)
                ? appCubit.startUpdate()
                : appCubit.downloadUpdate(),
            child: child,
          ),
        );
      },
    );
  }
}

class _CreateListButton extends StatelessWidget {
  const _CreateListButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: ListTile(
        leading: const Icon(Icons.add),
        title: const Text('New List'),
        onTap: () async {
          final String? newListName = await showInputDialog(
            context: context,
            title: 'Create New List',
            hintText: 'Name',
          );

          if (newListName == null || newListName == '') return;

          tasksCubit.createList(newListName);
        },
      ),
    );
  }
}

class _ScrollingListTiles extends StatelessWidget {
  const _ScrollingListTiles({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          return ReorderableListView(
            onReorder: (oldIndex, newIndex) => tasksCubit.reorderLists(
              oldIndex,
              newIndex,
            ),
            buildDefaultDragHandles: Platform.isAndroid || Platform.isIOS,
            children: state.taskLists
                .map((TaskList e) => _TaskListTile(
                      key: ValueKey(e.id),
                      taskList: e,
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class _TaskListTile extends StatefulWidget {
  final TaskList taskList;

  const _TaskListTile({
    Key? key,
    required this.taskList,
  }) : super(key: key);

  @override
  State<_TaskListTile> createState() => __TaskListTileState();
}

class __TaskListTileState extends State<_TaskListTile> {
  late TaskList taskList;

  @override
  void initState() {
    super.initState();
    taskList = widget.taskList;
  }

  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          return ListTile(
            key: ValueKey(taskList.id),
            title: Text(taskList.title),
            selected: (state.activeList == taskList),
            trailing: isHovered
                ? ReorderableDragStartListener(
                    index: taskList.index,
                    child: const Icon(Icons.drag_handle),
                  )
                : null,
            onTap: () {
              tasksCubit.setActiveList(taskList.id);
              if (platformIsMobile()) Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
