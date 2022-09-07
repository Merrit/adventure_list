import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import 'authentication/authentication.dart';
import 'authentication/sign_in_page.dart';
import 'home_widget/widgets/home_screen_widget.dart';
import 'home_widget/widgets/home_widget_config_page.dart';
import 'settings/widgets/settings_page.dart';
import 'shortcuts/app_shortcuts.dart';
import 'tasks/tasks.dart';
import 'theme/theme.dart';
import 'window/app_window.dart';

class App extends StatefulWidget {
  const App({
    Key? key,
  }) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WindowListener {
  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
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
        const Duration(seconds: 30),
        () {
          appWindow.saveWindowSizeAndPosition();
        },
      );
    }
    super.onWindowEvent(eventName);
  }

  @override
  Widget build(BuildContext context) {
    return AppShortcuts(
      child: BlocBuilder<AuthenticationCubit, AuthenticationState>(
        builder: (context, state) {
          final bool signedIn = state.signedIn;

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            restorationScopeId: 'app',
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
            ],
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context)!.appTitle,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.system,
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
                    case TaskDetails.routeName:
                      child = const TaskDetails();
                      break;
                    case TaskListSettingsPage.routeName:
                      child = const TaskListSettingsPage();
                      break;
                    case SettingsPage.routeName:
                      child = const SettingsPage();
                      break;
                    default:
                      child = const TasksPage();
                  }

                  return Platform.isAndroid
                      ? HomeScreenWidget(child: child)
                      : child;
                },
              );
            },
          );
        },
      ),
    );
  }
}
