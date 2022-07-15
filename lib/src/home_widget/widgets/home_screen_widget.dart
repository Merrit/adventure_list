import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'home_widget_config_page.dart';

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForWidgetLaunch();
    HomeWidget.widgetClicked.listen(_handleAppLaunchedFromHomeWidget);
  }

  void _checkForWidgetLaunch() {
    HomeWidget.initiallyLaunchedFromHomeWidget()
        .then(_handleAppLaunchedFromHomeWidget);
  }

  void _handleAppLaunchedFromHomeWidget(Uri? uri) {
    if (uri == null) return;

    if (uri.path == 'configureWidget') {
      Navigator.pushNamed(context, HomeWidgetConfigPage.routeName);
      return;
    }

    showDialog(
        context: context,
        builder: (buildContext) => AlertDialog(
              title: const Text('App started from HomeScreenWidget'),
              content: Text('Here is the URI: $uri'),
            ));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
