import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:helpers/helpers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/app/cubit/app_cubit.dart';
import 'src/authentication/authentication.dart';
import 'src/logs/logs.dart';
import 'src/notifications/notifications.dart';
import 'src/settings/cubit/settings_cubit.dart';
import 'src/storage/storage_repository.dart';
import 'src/system_tray/system_tray_manager.dart';
import 'src/tasks/tasks.dart';
import 'src/updates/updates.dart';
import 'src/window/window.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await LoggingManager.initialize(verbose: args.contains('--log'));

  // Handle platform errors not caught by Flutter.
  PlatformDispatcher.instance.onError = (error, stack) {
    log.e('Uncaught platform error:', error, stack);
    return true;
  };

  final storageRepository = await StorageRepository.initialize(Hive);

  if (defaultTargetPlatform.isDesktop) {
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
  );

  final notificationsCubit = await NotificationsCubit.initialize(
    flutterLocalNotificationsPlugin: FlutterLocalNotificationsPlugin(),
  );

  final tasksCubit = TasksCubit(authenticationCubit);
  final settingsCubitInstance = await SettingsCubit.initialize();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: googleAuth),
        RepositoryProvider.value(value: storageRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AppCubit(
              releaseNotesService: ReleaseNotesService(
                client: http.Client(),
                repository: 'merrit/adventure_list',
              ),
              updateService: UpdateService(),
            ),
          ),
          BlocProvider.value(value: authenticationCubit),
          BlocProvider.value(value: notificationsCubit),
          BlocProvider.value(value: settingsCubitInstance),
          BlocProvider.value(value: tasksCubit),
          if (defaultTargetPlatform.isDesktop)
            BlocProvider(
              create: (context) => WindowCubit(),
            ),
        ],
        child: const App(),
      ),
    ),
  );
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
