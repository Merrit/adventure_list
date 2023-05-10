import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart' as window_size;

import '../logs/logs.dart';
import '../settings/settings.dart';
import '../storage/storage_repository.dart';

class AppWindow {
  AppWindow() {
    instance = this;
  }

  static late final AppWindow instance;

  Future<void> initialize() async {
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions();
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await setWindowSizeAndPosition();
      await windowManager.show();
    });

    _listenForWindowClose();
  }

  void _listenForWindowClose() {
    if (!Platform.isLinux) return;

    /// For now using `flutter_window_close` on Linux, because the
    /// `onWindowClose` from `window_manager` is only working on Windows for
    /// some reason. Probably best to switch to only using `window_manager` if
    /// it starts also working on Linux in the future.
    FlutterWindowClose.setWindowShouldCloseHandler(() async {
      return await handleWindowCloseEvent();
    });
  }

  Future<bool> handleWindowCloseEvent() async {
    if (settingsCubit.state.closeToTray) {
      log.i('Hiding app window.');
      hide();
      return false;
    } else {
      // Hide window while performing sync, then exit.
      hide();
      log.i('Syncing before exit.');
      await Future.delayed(const Duration(seconds: 5));
      log.i('Sync finished, exiting.');
      return true;
    }
  }

  void close() => exit(0);

  /// Focuses the window.
  Future<void> focus() async => await windowManager.focus();

  Future<void> hide() async => await windowManager.hide();

  /// Reset window size and position to default.
  ///
  /// This will also center the window on the primary screen.
  /// Useful if the window is somehow moved off screen.
  Future<void> reset() async {
    await StorageRepository.instance.delete('windowSizeAndPosition');
    await setWindowSizeAndPosition();
  }

  /// Sets whether the window should be always on bottom.
  Future<void> setAlwaysOnBottom(bool alwaysOnBottom) async {
    await windowManager.setAlwaysOnBottom(alwaysOnBottom);
  }

  Future<void> setAsFrameless() async {
    await windowManager.setAsFrameless();
  }

  /// Sets the background color of the window.
  Future<void> setBackgroundColor(Color color) async {
    await windowManager.setBackgroundColor(color);
  }

  /// Sets whether the window should be shown in the taskbar.
  Future<void> setSkipTaskbar(bool skip) async {
    await windowManager.setSkipTaskbar(skip);
  }

  /// Sets the title bar visibility.
  Future<void> setTitleBarVisible(bool visible) async {
    final titleBarStyle = (visible) //
        ? TitleBarStyle.normal
        : TitleBarStyle.hidden;
    await windowManager.setTitleBarStyle(titleBarStyle);
  }

  Future<void> show() async => await windowManager.show();

  /// Saves the current window size and position to storage.
  ///
  /// Allows us to restore the window size and position on the next run.
  Future<void> saveWindowSizeAndPosition() async {
    final Rect bounds = await windowManager.getBounds();
    final screenConfigurationId = await _getScreenConfigurationId();

    log.v(
      'Saving window size and position. \n'
      'Screen configuration ID: $screenConfigurationId \n'
      'Window bounds: left: ${bounds.left}, top: ${bounds.top}, '
      'width: ${bounds.width}, height: ${bounds.height}',
    );

    await StorageRepository.instance.save(
      storageArea: 'windowSizeAndPosition',
      key: screenConfigurationId,
      value: bounds.toJson(),
    );
  }

  /// Sets the window size and position.
  ///
  /// If the window size and position has been saved previously, it will be
  /// restored. Otherwise, the window will be centered on the primary screen.
  Future<void> setWindowSizeAndPosition() async {
    log.v('Setting window size and position.');
    final screenConfigurationId = await _getScreenConfigurationId();
    final Rect currentWindowFrame = await windowManager.getBounds();

    final String? targetWindowFrameJson = await StorageRepository.instance.get(
      screenConfigurationId,
      storageArea: 'windowSizeAndPosition',
    );

    Rect? targetWindowFrame;
    if (targetWindowFrameJson != null) {
      targetWindowFrame = rectFromJson(targetWindowFrameJson);
    }

    targetWindowFrame ??= const Rect.fromLTWH(0, 0, 1100, 660);

    if (targetWindowFrame == currentWindowFrame) {
      log.v('Target matches current window frame, nothing to do.');
      return;
    }

    log.v(
      'Setting window size and position. \n'
      'Screen configuration ID: $screenConfigurationId \n'
      'Current window bounds: \n'
      'left: ${currentWindowFrame.left}, top: ${currentWindowFrame.top}, '
      'width: ${currentWindowFrame.width}, '
      'height: ${currentWindowFrame.height} \n'
      'Target window bounds: \n'
      'left: ${targetWindowFrame.left}, top: ${targetWindowFrame.top}, '
      'width: ${targetWindowFrame.width}, height: ${targetWindowFrame.height}',
    );

    await windowManager.setBounds(targetWindowFrame);

    // If first run, center window.
    if (targetWindowFrameJson == null) await windowManager.center();
  }

  /// Returns a unique identifier for the current configuration of screens.
  ///
  /// By using this, we can save the window position for each screen
  /// configuration, and then restore the window position for the current
  /// screen configuration.
  Future<String> _getScreenConfigurationId() async {
    final screens = await window_size.getScreenList();
    final StringBuffer buffer = StringBuffer();
    for (final screen in screens) {
      buffer
        ..write(screen.frame.left)
        ..write(screen.frame.top)
        ..write(screen.frame.width)
        ..write(screen.frame.height)
        ..write(screen.scaleFactor);
    }
    return buffer.toString();
  }
}

extension RectHelper on Rect {
  Map<String, dynamic> toMap() {
    return {
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    };
  }

  String toJson() => json.encode(toMap());
}

Rect rectFromJson(String source) {
  final Map<String, dynamic> map = json.decode(source);
  return Rect.fromLTWH(
    map['left'],
    map['top'],
    map['width'],
    map['height'],
  );
}
