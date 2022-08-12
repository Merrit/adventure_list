import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

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
  @override
  void initState() {
    super.initState();
    HomeWidget.widgetClicked.listen(_handleAppLaunchedFromHomeWidget);
  }

  void _handleAppLaunchedFromHomeWidget(Uri? uri) {
    if (uri == null) return;

    debugPrint('_HomeScreenWidgetState: uri: ${uri.path}');

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
          tasksCubit
              .setActiveList(settingsCubit.state.homeWidgetSelectedListId);
          Navigator.pushReplacementNamed(context, TasksPage.routeName);
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
