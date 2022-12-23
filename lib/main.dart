import 'dart:io';

import 'package:desktop_integration/desktop_integration.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';
import 'package:home_widget/home_widget.dart';
import 'package:window_manager/window_manager.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/app/cubit/app_cubit.dart';
import 'src/authentication/authentication.dart';
import 'src/core/constants.dart';
import 'src/logs/logs.dart';
import 'src/settings/cubit/settings_cubit.dart';
import 'src/storage/storage_service.dart';
import 'src/system_tray/system_tray_manager.dart';
import 'src/tasks/tasks.dart';
import 'src/window/app_window.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final storageService = await StorageService.initialize();
  await initializeLogger(storageService, logToFile: args.contains('--log'));

  // Handle errors caught by Flutter.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode && Platform.isWindows) {
      logger.e('Flutter caught an error:', details.exception, details.stack);
    }
  };

  // Handle platform errors not caught by Flutter.
  PlatformDispatcher.instance.onError = (exception, stackTrace) {
    logger.e('Platform caught an error:', exception, stackTrace);
    return false;
  };

  if (Platform.isLinux || Platform.isWindows) {
    final appWindow = AppWindow() //
      ..initialize();
    final systemTray = SystemTrayManager(appWindow);
    await systemTray.initialize();
  }

  // Firebase not available on Linux & Windows.
  if (!Platform.isLinux && !Platform.isWindows) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  if (Platform.isAndroid) {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
    HomeWidget.registerBackgroundCallback(backgroundCallback);
  }

  final googleAuth = GoogleAuth();
  final authenticationCubit = await AuthenticationCubit.initialize(
    googleAuth: googleAuth,
    storageService: storageService,
  );

  final tasksCubit = TasksCubit(authenticationCubit, storageService);
  final settingsCubitInstance = await SettingsCubit.initialize(storageService);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: googleAuth),
        RepositoryProvider.value(value: storageService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AppCubit(settingsCubitInstance),
            lazy: false,
          ),
          BlocProvider(create: (context) => authenticationCubit),
          BlocProvider.value(value: settingsCubitInstance),
          BlocProvider.value(value: tasksCubit),
        ],
        child: const App(),
      ),
    ),
  );

  integrateWithDesktop();
}

/// Add the app to the user's applications menu with icon.
Future<void> integrateWithDesktop() async {
  if (!Platform.isLinux && !Platform.isWindows) return;
  if (kDebugMode) return;

  File? desktopFile;
  if (Platform.isLinux) {
    desktopFile = await assetToTempDir(
      'packaging/linux/codes.merritt.adventurelist.desktop',
    );
  }

  final iconFileSuffix = Platform.isWindows ? 'ico' : 'svg';

  final iconFile = await assetToTempDir(
    'assets/icons/codes.merritt.adventurelist.$iconFileSuffix',
  );

  final desktopIntegration = DesktopIntegration(
    desktopFilePath: desktopFile?.path ?? '',
    iconPath: iconFile.path,
    packageName: kPackageId,
    linkFileName: 'Adventure List',
  );

  await desktopIntegration.addToApplicationsMenu();
}

/// Used for Background Updates using Workmanager Plugin
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) {
    final now = DateTime.now();
    return Future.wait<bool?>([
      HomeWidget.saveWidgetData(
        'title',
        'Updated from Background',
      ),
      HomeWidget.saveWidgetData(
        'message',
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      ),
      HomeWidget.updateWidget(
        name: 'HomeWidgetExampleProvider',
        iOSName: 'HomeWidgetExample',
      ),
    ]).then((value) {
      return !value.contains(false);
    });
  });
}

/// Called when Doing Background Work initiated from Widget
Future<void> backgroundCallback(Uri? data) async {
  // Not currently used.
  // if (data?.host == 'titleclicked') {
  //   final greetings = [
  //     'frog',
  //     'fox',
  //     'wolf',
  //     'amaterasu',
  //   ];
  //   final selectedGreeting = greetings[Random().nextInt(greetings.length)];

  //   await updateHomeWidget('title', selectedGreeting);
  // }
}
