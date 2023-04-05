import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

import '../core/core.dart';
import '../window/app_window.dart';

class SystemTrayManager {
  final AppWindow _window;

  SystemTrayManager(this._window);

  Future<void> initialize() async {
    final String iconPath = Platform.isWindows
        ? 'assets/icons/$kPackageId.ico'
        : 'assets/icons/$kPackageId-symbolic.svg';

    await trayManager.setIcon(iconPath);

    final Menu menu = Menu(
      items: [
        MenuItem(label: 'Show', onClick: (menuItem) => _window.show()),
        MenuItem(label: 'Hide', onClick: (menuItem) => _window.hide()),
        MenuItem(label: 'Exit', onClick: (menuItem) => _window.close()),
      ],
    );

    await trayManager.setContextMenu(menu);
  }
}
