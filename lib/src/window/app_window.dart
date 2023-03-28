// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:window_manager/window_manager.dart';

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
  Future<void> hide() async => await windowManager.hide();
  Future<void> show() async => await windowManager.show();

  Future<void> saveWindowSizeAndPosition() async {
    print('Saving window size and position');
    final Rect bounds = await windowManager.getBounds();

    await StorageRepository.instance.save(
      key: 'windowSizeAndPosition',
      value: bounds.toJson(),
    );
  }

  Future<void> setWindowSizeAndPosition() async {
    print('Setting window size and position.');
    final Rect currentWindowFrame = await windowManager.getBounds();

    final String? targetWindowFrameJson = await StorageRepository.instance.get(
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
