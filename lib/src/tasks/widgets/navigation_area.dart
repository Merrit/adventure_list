import 'dart:io';

import 'package:badges/badges.dart' as badges;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../../app/cubit/app_cubit.dart';
import '../../core/helpers/helpers.dart';
import '../../settings/widgets/settings_page.dart';
import '../../window/window.dart';
import '../tasks.dart';

class CustomNavigationRail extends StatelessWidget {
  final Breakpoint breakpoint;

  const CustomNavigationRail({
    Key? key,
    required this.breakpoint,
  }) : super(key: key);

  static const double width = 192;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (breakpoint == Breakpoints.small) {
          return const Drawer(
            child: _NavContents(),
          );
        } else {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: width),
            child: const _NavContents(),
          );
        }
      },
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
        _SettingsTile(),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return ListTile(
          title: badges.Badge(
            showBadge: state.showUpdateButton,
            badgeStyle: const badges.BadgeStyle(
              badgeColor: Colors.lightBlue,
            ),
            child: const Text('Settings'),
          ),
          trailing: const _PinWindowButton(),
          onTap: () => Navigator.pushNamed(context, SettingsPage.routeName),
        );
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

/// Button to pin the window to the desktop as a widget.
class _PinWindowButton extends StatelessWidget {
  const _PinWindowButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!defaultTargetPlatform.isDesktop) return const SizedBox();

    return BlocBuilder<WindowCubit, WindowState>(
      builder: (context, state) {
        final icon = (state.pinned) //
            ? Icons.push_pin
            : Icons.push_pin_outlined;

        return IconButton(
          icon: Icon(icon),
          onPressed: () => WindowCubit.instance.togglePinned(),
        );
      },
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
    final mediaQuery = MediaQuery.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          final taskList = state.taskLists.singleWhere(
            (element) => element.id == widget.taskList.id,
          );

          final overdueTasks = taskList.items.overdueTasks();

          return ListTile(
            key: ValueKey(taskList.id),
            title: badges.Badge(
              showBadge: overdueTasks.isNotEmpty,
              badgeContent: Text(
                overdueTasks.length.toString(),
                style: const TextStyle(color: Colors.white),
              ),
              child: Text(taskList.title),
            ),
            selected: (state.activeList == taskList),
            trailing: isHovered
                ? ReorderableDragStartListener(
                    index: taskList.index,
                    child: const Icon(Icons.drag_handle),
                  )
                : null,
            onTap: () {
              tasksCubit.setActiveList(taskList.id);
              if (mediaQuery.isSmallScreen) Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
