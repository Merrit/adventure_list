import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../autostart/autostart_service.dart';
import '../../core/core.dart';
import '../../logs/logging_manager.dart';
import '../../storage/storage_repository.dart';
import '../../theme/theme.dart';
import '../settings.dart';

part 'settings_state.dart';
part 'settings_cubit.freezed.dart';

class SettingsCubit extends Cubit<SettingsState> {
  /// Service for managing autostart.
  final AutostartService _autostartService;

  /// Repository for managing storage.
  final StorageRepository _storageRepository;

  SettingsCubit(
    this._autostartService,
    this._storageRepository, {
    required SettingsState initialState,
  }) : super(initialState);

  static Future<SettingsCubit> initialize(
    AutostartService autostartService,
    StorageRepository storageRepository,
  ) async {
    final String? desktopWidgetSettingsJson = await StorageRepository //
        .instance
        .get('desktopWidgetSettings');

    final desktopWidgetSettings = (desktopWidgetSettingsJson != null)
        ? DesktopWidgetSettings.fromJson(
            Map<String, dynamic>.from(jsonDecode(desktopWidgetSettingsJson)),
          )
        : DesktopWidgetSettings.initial();

    final String? homeWidgetSelectedListId = await StorageRepository //
        .instance
        .get('homeWidgetSelectedListId');

    return SettingsCubit(
      autostartService,
      storageRepository,
      initialState: SettingsState(
        autostart: await StorageRepository.instance.get('autostart') ?? false,
        closeToTray: await StorageRepository.instance.get('closeToTray') ?? true,
        desktopWidgetSettings: desktopWidgetSettings,
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

    final Brightness systemBrightness = WidgetsBinding //
        .instance
        .platformDispatcher
        .platformBrightness;

    switch (savedThemePreference) {
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.light':
        return ThemeMode.light;
      case null:
      default:
        return (systemBrightness == Brightness.dark) ? ThemeMode.dark : ThemeMode.light;
    }
  }

  /// Set whether or not to show verbose logging.
  Future<void> setVerboseLogging(bool value) async {
    await LoggingManager.initialize(verbose: value);
    await _storageRepository.save(key: 'verboseLogging', value: value);
  }

  /// Toggle autostart on Desktop.
  Future<void> toggleAutostart() async {
    assert(defaultTargetPlatform.isDesktop);

    if (state.autostart) {
      await _autostartService.disable();
    } else {
      await _autostartService.enable();
    }

    emit(state.copyWith(autostart: !state.autostart));
    await StorageRepository.instance.save(
      key: 'autostart',
      value: state.autostart,
    );
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

  /// Update and persist the [DesktopWidgetSettings].
  Future<void> updateDesktopWidgetSettings(
    DesktopWidgetSettings newSettings,
  ) async {
    emit(state.copyWith(desktopWidgetSettings: newSettings));

    await StorageRepository.instance.save(
      key: 'desktopWidgetSettings',
      value: jsonEncode(newSettings.toJson()),
    );
  }
}
