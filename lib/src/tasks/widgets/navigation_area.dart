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
                  builder: (context) => const SettingsDialog(),
                );
              }
            },
          ),
          const VersionButton(),
          const UpdateButton(),
        ],
      ),
    );
  }
}

class VersionButton extends StatelessWidget {
  const VersionButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return ListTile(
          title: Opacity(
            opacity: 0.5,
            child: Text(
              'Version ${state.appVersion}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          onTap: () => showDialog(
            context: context,
            builder: (context) => const VersionDialog(),
          ),
        );
      },
    );
  }
}

class VersionDialog extends StatelessWidget {
  const VersionDialog({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // aboutdialog
    return AlertDialog(
      content: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Current version: ${state.appVersion}'),
                subtitle: state.updateAvailable
                    ? Text('Update available: ${state.updateVersion}')
                    : const Text('No update available'),
              ),
            ],
          );
        },
      ),
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
            child: CircularProgressIndicator(color: Colors.pink.shade400),
          );
        } else {
          child = const Text('UPDATE');
        }

        return ListTile(
          title: ElevatedButton(
            onPressed: () => appCubit.startUpdate(),
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
