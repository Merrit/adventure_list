import 'package:tray_manager/tray_manager.dart';

import '../core/core.dart';
import '../logs/logging_manager.dart';
import '../window/window.dart';

/// Manages the system tray icon.
class SystemTrayManager {
  final AppWindow _window;

  /// The singleton instance of this class.
  static late SystemTrayManager instance;

  SystemTrayManager(this._window) {
    instance = this;
  }

  Future<void> initialize() async {
    final String iconPath = AppIcons.platformSpecific(
      symbolic: true,
      withNotificationBadge: false,
    );

    await trayManager.setIcon(iconPath);

    final Menu menu = Menu(
      items: [
        MenuItem(label: 'Show', onClick: (menuItem) => _window.show()),
        MenuItem(label: 'Hide', onClick: (menuItem) => _window.hide()),
        MenuItem(label: 'Reset Window', onClick: (_) => _resetWindow()),
        MenuItem(label: 'Exit', onClick: (menuItem) => _window.close()),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  /// Sets the system tray icon.
  Future<void> setIcon(String iconPath) async {
    log.t('Setting system tray icon to $iconPath');
    await trayManager.setIcon(iconPath);
  }

  /// Reset the window size and position.
  ///
  /// In addition if the window is pinned, it will be unpinned.
  Future<void> _resetWindow() async {
    if (WindowCubit.instance.state.pinned) {
      await WindowCubit.instance.togglePinned();
    }

    await _window.reset();
  }
}
