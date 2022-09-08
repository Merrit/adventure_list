// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:window_manager/window_manager.dart';

import '../settings/settings.dart';
import '../storage/storage_service.dart';

final appWindow = AppWindow();

class AppWindow {
  AppWindow._() {
    instance = this;
  }

  static late final AppWindow instance;
  static bool _initialized = false;

  factory AppWindow() {
    if (_initialized) return instance;

    _initialized = true;
    return AppWindow._();
  }

  void initialize() {
    if (defaultTargetPlatform != TargetPlatform.linux &&
        defaultTargetPlatform != TargetPlatform.windows &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    WindowOptions windowOptions = const WindowOptions();
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
      if (settingsCubit.state.closeToTray) {
        hide();
        return false;
      } else {
        return true;
      }
    });
  }

  Future<void> catchClose() async {
    print('catching close');
    await windowManager.setClosable(false);
    // hide();
  }

  void close() => exit(0);
  Future<void> hide() async => await windowManager.hide();
  Future<void> show() async => await windowManager.show();

  Future<void> saveWindowSizeAndPosition() async {
    print('Saving window size and position');
    final Rect bounds = await windowManager.getBounds();

    await StorageService.instance!.saveValue(
      key: 'windowSizeAndPosition',
      value: bounds.toJson(),
    );
  }

  Future<void> setWindowSizeAndPosition() async {
    print('Setting window size and position.');
    Rect currentWindowFrame = await windowManager.getBounds();

    String? targetWindowFrameJson = await StorageService.instance!.getValue(
      'windowSizeAndPosition',
    );

    Rect? targetWindowFrame;
    if (targetWindowFrameJson != null) {
      targetWindowFrame = rectFromJson(targetWindowFrameJson);
    }

    targetWindowFrame ??= const Rect.fromLTWH(0, 0, 1100, 660);

    if (targetWindowFrame == currentWindowFrame) {
      print('Target matches current window frame, nothing to do.');
      return;
    }

    await windowManager.setBounds(targetWindowFrame);

    // If first run, center window.
    if (targetWindowFrameJson == null) await windowManager.center();
  }
}

extension on Rect {
  Map<String, dynamic> toMap() {
    return {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    };
  }

  String toJson() => json.encode(toMap());
}

Rect rectFromJson(String source) {
  final Map<String, dynamic> map = json.decode(source);
  return Rect.fromLTRB(
    map['left'],
    map['top'],
    map['right'],
    map['bottom'],
  );
}
