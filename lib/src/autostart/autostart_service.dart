import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:helpers/helpers.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

import '../logs/logging_manager.dart';

/// Service to enable/disable autostart on desktop platforms.
class AutostartService {
  /// Disables autostart on login.
  Future<void> disable() async {
    assert(defaultTargetPlatform.isDesktop);

    if (runningInFlatpak()) {
      await _setForFlatpak(false);
    } else {
      await _disableForDesktop();
    }
  }

  /// Enables autostart on login.
  Future<void> enable() async {
    assert(defaultTargetPlatform.isDesktop);

    if (runningInFlatpak()) {
      await _setForFlatpak(true);
    } else {
      await _enableForDesktop();
    }
  }

  Future<void> _disableForDesktop() async {
    await _setupLaunchAtStartup();
    await launchAtStartup.disable();
  }

  Future<void> _enableForDesktop() async {
    await _setupLaunchAtStartup();
    await launchAtStartup.enable();
  }

  Future<void> _setForFlatpak(bool enable) async {
    log.i('Setting up autostart for Flatpak app.');
    final client = XdgDesktopPortalClient();

    final result = await client.background.requestBackground(
      reason: 'Autostarting Adventure List',
      autostart: enable,
      commandLine: ['adventure_list'],
    ).first;

    log.i('Result: $result');
    await client.close();
  }

  Future<void> _setupLaunchAtStartup() async {
    final packageInfo = await PackageInfo.fromPlatform();

    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );
  }
}
