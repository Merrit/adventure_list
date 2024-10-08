import 'package:badges/badges.dart' as badges;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../../../generated/locale_keys.g.dart';
import '../../app/cubit/app_cubit.dart';
import '../../settings/widgets/settings_page.dart';
import '../../window/window.dart';
import '../tasks.dart';

class CustomNavigationRail extends StatelessWidget {
  final Breakpoint breakpoint;

  const CustomNavigationRail({
    super.key,
    required this.breakpoint,
  });

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
  const _NavContents();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _CreateListButton(),
        _ScrollingListTiles(),
        _SettingsTile(),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile();

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
            child: Text(LocaleKeys.settings_settings.tr()),
          ),
          trailing: const _PinWindowButton(),
          onTap: () => Navigator.pushNamed(context, SettingsPage.routeName),
        );
      },
    );
  }
}

class _CreateListButton extends StatelessWidget {
  const _CreateListButton();

  @override
  Widget build(BuildContext context) {
    final tasksCubit = context.read<TasksCubit>();

    return TextInputListTile(
      leading: const Icon(Icons.add),
      placeholderText: LocaleKeys.newList.tr(),
      callback: (String value) => tasksCubit.createList(value),
    );
  }
}

/// Button to pin the window to the desktop as a widget.
class _PinWindowButton extends StatelessWidget {
  const _PinWindowButton();

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
          tooltip: LocaleKeys.pinWindow.tr(),
        );
      },
    );
  }
}

class _ScrollingListTiles extends StatelessWidget {
  const _ScrollingListTiles();

  @override
  Widget build(BuildContext context) {
    final tasksCubit = context.read<TasksCubit>();

    return Expanded(
      child: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          return ReorderableListView(
            onReorder: (oldIndex, newIndex) => tasksCubit.reorderLists(
              oldIndex,
              newIndex,
            ),
            buildDefaultDragHandles: defaultTargetPlatform.isMobile,
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
    super.key,
    required this.taskList,
  });

  @override
  State<_TaskListTile> createState() => __TaskListTileState();
}

class __TaskListTileState extends State<_TaskListTile> {
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final tasksCubit = context.read<TasksCubit>();

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final taskList = state.taskLists.singleWhere(
          (element) => element.id == widget.taskList.id,
        );

        final overdueTasks = taskList.items.overdueTasks();

        final listTile = ListTile(
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
          onTap: () {
            tasksCubit.setActiveList(taskList.id);
            if (mediaQuery.isSmallScreen) Navigator.pop(context);
          },
        );

        if (defaultTargetPlatform.isMobile) {
          return listTile;
        } else {
          return ReorderableDragStartListener(
            index: taskList.index,
            child: listTile,
          );
        }
      },
    );
  }
}
