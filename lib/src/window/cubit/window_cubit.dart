import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../settings/settings.dart';
import '../window.dart';

part 'window_state.dart';
part 'window_cubit.freezed.dart';

class WindowCubit extends Cubit<WindowState> {
  final SettingsCubit settingsCubit;

  /// Singleton instance of the [WindowCubit].
  static late WindowCubit instance;

  WindowCubit(this.settingsCubit) : super(WindowState.initial()) {
    instance = this;
  }

  /// Toggles the pinned state of the window.
  Future<void> togglePinned() async {
    final bool transparentBackgroundEnabled = settingsCubit //
        .state
        .desktopWidgetSettings
        .transparentBackground;

    final backgroundColor = (!state.pinned && transparentBackgroundEnabled)
        ? Colors.transparent
        : Colors.white;

    await AppWindow.instance.setAlwaysOnBottom(!state.pinned);
    await AppWindow.instance.setAsFrameless();
    await AppWindow.instance.setBackgroundColor(backgroundColor);
    await AppWindow.instance.setSkipTaskbar(!state.pinned);
    await AppWindow.instance.setTitleBarVisible(state.pinned);
    emit(state.copyWith(pinned: !state.pinned));
  }
}
