import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';

import '../../logs/logging_manager.dart';
import '../../settings/settings.dart';
import '../../tasks/tasks.dart';
import 'home_widget_config_page.dart';

/// Manages the state for the Android home screen widget / AppWidget.
class HomeScreenWidget extends StatefulWidget {
  final Widget child;

  const HomeScreenWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<HomeScreenWidget> createState() => _HomeScreenWidgetState();
}

class _HomeScreenWidgetState extends State<HomeScreenWidget> {
  StreamSubscription? homeWidgetListener;
  late SettingsCubit settingsCubit;
  late TasksCubit tasksCubit;

  @override
  void initState() {
    super.initState();
    homeWidgetListener = HomeWidget.widgetClicked.listen(
      _handleAppLaunchedFromHomeWidget,
    );

    settingsCubit = context.read<SettingsCubit>();
    tasksCubit = context.read<TasksCubit>();
  }

  @override
  void dispose() {
    homeWidgetListener?.cancel();
    super.dispose();
  }

  void _handleAppLaunchedFromHomeWidget(Uri? uri) {
    if (uri == null) return;

    log.i('_HomeScreenWidgetState: uri: ${uri.path}');

    final navigator = Navigator.of(context);

    switch (uri.path) {
      case 'configureWidget':
        navigator.pushReplacementNamed(HomeWidgetConfigPage.routeName);
        return;
      case 'launchWidgetList':
        final selectedListId = settingsCubit.state.homeWidgetSelectedListId;
        if (selectedListId == '') {
          // No selected list, launch selection dialog.
          navigator.pushReplacementNamed(HomeWidgetConfigPage.routeName);
        } else {
          tasksCubit.setActiveList(settingsCubit.state.homeWidgetSelectedListId);
          // Ensure we are on the TasksPage when launched from the android
          // widget.
          navigator.popUntil((route) => route.isFirst);
          // Check if the drawer is open and close it.
          if (navigator.canPop()) {
            navigator.pop();
          }
        }
        return;
      default:
        showDialog(
          context: context,
          builder: (buildContext) => AlertDialog(
            title: const Text('App started from HomeScreenWidget'),
            content: Text('Here is the URI: $uri'),
          ),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
