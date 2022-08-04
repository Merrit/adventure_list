import 'dart:io';

import 'package:window_manager/window_manager.dart';

class AppWindow {
  AppWindow._();

  static Future<AppWindow?> initialize() async {
    if (Platform.isAndroid || Platform.isIOS) return null;

    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      title: 'Adventure List',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // await windowManager.show();
      // await windowManager.focus();
    });

    return AppWindow._();
  }
}
