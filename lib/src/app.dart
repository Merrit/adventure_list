import 'dart:io';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'authentication/authentication.dart';
import 'authentication/login_page.dart';
import 'home_widget/widgets/home_screen_widget.dart';
import 'home_widget/widgets/home_widget_config_page.dart';
import 'settings/widgets/settings_page.dart';
import 'storage/storage_service.dart';
import 'tasks/tasks.dart';

TasksCubit? _tasksCubit;

class App extends StatelessWidget {
  const App({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationCubit, AuthenticationState>(
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
          theme: FlexThemeData.light(
            scheme: FlexScheme.blue,
            surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
            blendLevel: 20,
            appBarOpacity: 0.95,
            subThemesData: const FlexSubThemesData(
              blendOnLevel: 20,
              blendOnColors: false,
            ),
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
            // useMaterial3: true,
            fontFamily: GoogleFonts.notoSans().fontFamily,
          ),
          darkTheme: FlexThemeData.dark(
            scheme: FlexScheme.blue,
            surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
            blendLevel: 40,
            appBarStyle: FlexAppBarStyle.background,
            appBarOpacity: 0.90,
            subThemesData: const FlexSubThemesData(
              blendOnLevel: 30,
            ),
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
            // useMaterial3: true,
            fontFamily: GoogleFonts.notoSans().fontFamily,
          ),
          themeMode: ThemeMode.system,
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                if (!signedIn) return const LoginPage();

                switch (routeSettings.name) {
                  case HomeWidgetConfigPage.routeName:
                    return const RouteWrapper(child: HomeWidgetConfigPage());
                  case LoginPage.routeName:
                    return const LoginPage();
                  case TaskDetails.routeName:
                    return const RouteWrapper(child: TaskDetails());
                  case TaskListSettingsPage.routeName:
                    return const RouteWrapper(child: TaskListSettingsPage());
                  case SettingsPage.routeName:
                    return const RouteWrapper(child: SettingsPage());
                  default:
                    // Only create cubit once.
                    if (_tasksCubit != null) {
                      return const RouteWrapper(child: TasksPage());
                    }

                    // Cubit not created yet, create now.
                    final tasksRepository = TasksRepository.initialize(
                      clientId: GoogleAuthIds.clientId,
                      credentials: state.accessCredentials!,
                    );

                    return FutureBuilder(
                      future: tasksRepository,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();

                        _tasksCubit = TasksCubit(
                          context.read<StorageService>(),
                          snapshot.data as TasksRepository,
                        );

                        return const RouteWrapper(child: TasksPage());
                      },
                    );
                }
              },
            );
          },
        );
      },
    );
  }
}

/// Wrap all routes in a BlocProvider to the TasksCubit & the Android AppWidget
/// manager; this way it doesn't have to be done for every route.
class RouteWrapper extends StatelessWidget {
  final Widget child;

  const RouteWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _tasksCubit!,
      child: Platform.isAndroid ? HomeScreenWidget(child: child) : child,
    );
  }
}
