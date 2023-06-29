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

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/app/cubit/app_cubit.dart';
import 'src/authentication/authentication.dart';
import 'src/autostart/autostart_service.dart';
import 'src/background_tasks/background_tasks.dart';
import 'src/core/helpers/helpers.dart';
import 'src/home_widget/home_widget.dart';
import 'src/logs/logging_manager.dart';
import 'src/notifications/notifications.dart';
import 'src/settings/cubit/settings_cubit.dart';
import 'src/storage/storage_repository.dart';
import 'src/system_tray/system_tray_manager.dart';
import 'src/tasks/tasks.dart';
import 'src/updates/updates.dart';
import 'src/window/window.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool verbose =
      args.contains('--verbose') || const bool.fromEnvironment('VERBOSE');

  await LoggingManager.initialize(verbose: verbose);
  initializePlatformErrorHandler();

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
    HomeWidget.registerBackgroundCallback(backgroundCallback);
  }

  final googleAuth = GoogleAuth(storageRepository);
  final authenticationCubit = await AuthenticationCubit.initialize(
    googleAuth: googleAuth,
    storageRepository: storageRepository,
  );

  final notificationsCubit = await NotificationsCubit.initialize(
    flutterLocalNotificationsPlugin: FlutterLocalNotificationsPlugin(),
  );

  final homeWidgetManager = HomeWidgetManager();

  final tasksCubit = TasksCubit(
    authenticationCubit,
    googleAuth,
    homeWidgetManager,
  );

  final settingsCubitInstance = await SettingsCubit.initialize(
    AutostartService(),
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: googleAuth),
        RepositoryProvider.value(value: homeWidgetManager),
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

  initializeBackgroundTasks();
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
