import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';

import '../core/core.dart';
import '../window/app_window.dart';

/// Manages the system tray icon.
class SystemTrayManager {
  final AppWindow _window;

  /// The singleton instance of this class.
  static late SystemTrayManager instance;

  SystemTrayManager(this._window) {
    instance = this;
  }

  Future<void> initialize() async {
    final String iconPath = (defaultTargetPlatform.isWindows) //
        ? AppIcons.windows
        : AppIcons.linux;

    await trayManager.setIcon(iconPath);

    final Menu menu = Menu(
      items: [
        MenuItem(label: 'Show', onClick: (menuItem) => _window.show()),
        MenuItem(label: 'Hide', onClick: (menuItem) => _window.hide()),
        MenuItem(label: 'Reset Window', onClick: (menuItem) => _window.reset()),
        MenuItem(label: 'Exit', onClick: (menuItem) => _window.close()),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  /// Sets the system tray icon.
  Future<void> setIcon(String iconPath) async {
    await trayManager.setIcon(iconPath);
  }
}
