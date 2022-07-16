import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
                  builder: (context) {
                    return const SettingsView();
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _CreateListButton extends StatelessWidget {
  const _CreateListButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add),
      onPressed: () async {
        final String? newListName = await showInputDialog(
          context: context,
          title: 'Create New List',
          hintText: 'Name',
        );

        if (newListName == null || newListName == '') return;

        tasksCubit.createList(newListName);
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
