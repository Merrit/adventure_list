import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:system_theme/system_theme.dart';

import '../../storage/storage_repository.dart';
import '../../theme/theme.dart';

part 'settings_state.dart';

late final SettingsCubit settingsCubit;

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required SettingsState initialState}) : super(initialState) {
    settingsCubit = this;
  }

  static Future<SettingsCubit> initialize() async {
    String? homeWidgetSelectedListId = await StorageRepository.instance.get(
      'homeWidgetSelectedListId',
    );

    return SettingsCubit(
      initialState: SettingsState(
        closeToTray:
            await StorageRepository.instance.get('closeToTray') ?? true,
        homeWidgetSelectedListId: homeWidgetSelectedListId ?? '',
        theme: await _getTheme(),
      ),
    );
  }

  /// Returns the [ThemeData] based on the user's choice of desired [ThemeMode].
  static Future<ThemeData> _getTheme() async {
    final themeMode = await _getThemeMode();
    switch (themeMode) {
      case ThemeMode.light:
        return lightTheme;
      case ThemeMode.dark:
      default:
        return darkTheme;
    }
  }

  /// Returns the [ThemeMode] based on the user's choice of desired [ThemeMode].
  ///
  /// If the user has not made a choice, the system's theme is used.
  static Future<ThemeMode> _getThemeMode() async {
    final String? savedThemePreference = await StorageRepository.instance.get(
      'ThemeMode',
    );

    switch (savedThemePreference) {
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.light':
        return ThemeMode.light;
      case null:
      default:
        return (SystemTheme.isDarkMode) ? ThemeMode.dark : ThemeMode.light;
    }
  }

  Future<void> updateCloseToTray(bool value) async {
    emit(state.copyWith(closeToTray: value));
    await StorageRepository.instance.save(
      key: 'closeToTray',
      value: value,
    );
  }

  Future<void> updateHomeWidgetSelectedListId(String id) async {
    emit(state.copyWith(homeWidgetSelectedListId: id));
    await StorageRepository.instance.save(
      key: 'homeWidgetSelectedListId',
      value: id,
    );
  }

  /// Update and persist the ThemeMode based on the user's selection.
  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;

    final newTheme = (newThemeMode == ThemeMode.light) //
        ? lightTheme
        : darkTheme;

    emit(state.copyWith(theme: newTheme));

    await StorageRepository.instance.save(
      key: 'ThemeMode',
      value: newThemeMode.toString(),
    );
  }
}
