import 'dart:io';
import 'dart:math';

import 'package:desktop_integration/desktop_integration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import 'src/app.dart';
import 'src/app/cubit/app_cubit.dart';
import 'src/authentication/authentication.dart';
import 'src/constants.dart';
import 'src/home_widget/home_widget.dart';
import 'src/logs/logs.dart';
import 'src/settings/cubit/settings_cubit.dart';
import 'src/storage/storage_service.dart';
import 'src/window/app_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppWindow.initialize();

  if (Platform.isAndroid) {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
    HomeWidget.registerBackgroundCallback(backgroundCallback);
  }

  final storageService = await StorageService.initialize();

  await initializeLogger(storageService);

  final googleAuth = GoogleAuth();
  final authenticationCubit = await AuthenticationCubit.initialize(
    googleAuth: googleAuth,
    storageService: storageService,
  );

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
    packageName: kpackageId,
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
  if (data?.host == 'titleclicked') {
    final greetings = [
      'frog',
      'fox',
      'wolf',
      'amaterasu',
    ];
    final selectedGreeting = greetings[Random().nextInt(greetings.length)];

    await updateHomeWidget('title', selectedGreeting);
  }
}
