import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../../app/cubit/app_cubit.dart';
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
      children: const [
        _CreateListButton(),
        _ScrollingListTiles(),
        _SettingsButton(),
      ],
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Stack(
        children: [
          const Text('Settings'),
          Positioned(
            left: 64,
            top: 4,
            child: BlocBuilder<AppCubit, AppState>(
              builder: (context, state) {
                return Icon(
                  Icons.circle,
                  color: state.updateAvailable //
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.transparent,
                  size: 8,
                );
              },
            ),
          )
        ],
      ),
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
    );
  }
}

class _CreateListButton extends StatelessWidget {
  const _CreateListButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextInputListTile(
      leading: const Icon(Icons.add),
      placeholderText: 'New List',
      callback: (String value) => tasksCubit.createList(value),
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
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          final taskList = state.taskLists.singleWhere(
            (element) => element.id == widget.taskList.id,
          );

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
