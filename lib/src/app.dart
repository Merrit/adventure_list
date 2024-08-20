import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../generated/locale_keys.g.dart';
import 'authentication/authentication.dart';
import 'authentication/sign_in_page.dart';
import 'home_widget/widgets/home_screen_widget.dart';
import 'home_widget/widgets/home_widget_config_page.dart';
import 'settings/settings.dart';
import 'shortcuts/app_shortcuts.dart';
import 'tasks/tasks.dart';
import 'window/app_window.dart';

class App extends StatefulWidget {
  const App({
    super.key,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with TrayListener, WindowListener {
  @override
  void initState() {
    if (defaultTargetPlatform.isDesktop) {
      trayManager.addListener(this);
      windowManager.addListener(this);
    }
    super.initState();
  }

  @override
  void dispose() {
    if (defaultTargetPlatform.isDesktop) {
      trayManager.removeListener(this);
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
    super.onTrayIconMouseUp();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
    super.onTrayIconRightMouseUp();
  }

  @override
  Future<void> onWindowClose() async {
    /// This method from the `window_manager` package is only working on Windows
    /// for some reason. Linux will use `flutter_window_close` instead until it
    /// has been resolved.
    final bool allowClose = await AppWindow.instance.handleWindowCloseEvent();
    if (allowClose) super.onWindowClose();
  }

  Timer? timer;

  @override
  void onWindowEvent(String eventName) {
    if (eventName == 'move' || eventName == 'resize') {
      /// Set a timer between events that trigger saving the window size and
      /// location. This is required because there is no notification available
      /// for when these events *finish*, and therefore it would be triggered
      /// hundreds of times otherwise during a move event.
      timer?.cancel();
      timer = null;
      timer = Timer(
        const Duration(seconds: 5),
        () {
          AppWindow.instance.saveWindowSizeAndPosition();
        },
      );
    }
    super.onWindowEvent(eventName);
  }

  @override
  Widget build(BuildContext context) {
    return AppShortcuts(
      child: BlocBuilder<AuthenticationCubit, AuthenticationState>(
        builder: (context, authState) {
          final bool signedIn = authState.signedIn;

          return BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsState) {
              return MaterialApp(
                restorationScopeId: 'app',
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                onGenerateTitle: (BuildContext context) => LocaleKeys.appName,
                theme: settingsState.theme,
                onGenerateRoute: (RouteSettings routeSettings) {
                  return MaterialPageRoute<void>(
                    settings: routeSettings,
                    builder: (BuildContext context) {
                      if (!signedIn) return const SignInPage();

                      Widget child;

                      switch (routeSettings.name) {
                        case HomeWidgetConfigPage.routeName:
                          child = const HomeWidgetConfigPage();
                          break;
                        case SignInPage.routeName:
                          child = const SignInPage();
                          break;
                        case TaskDetailsWidget.routeName:
                          child = const TaskDetailsWidget();
                          break;
                        case SettingsPage.routeName:
                          child = const SettingsPage();
                          break;
                        default:
                          child = const TasksPage();
                      }

                      return Platform.isAndroid ? HomeScreenWidget(child: child) : child;
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
