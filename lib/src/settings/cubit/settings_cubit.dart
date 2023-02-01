import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../storage/storage_service.dart';

part 'settings_state.dart';

late final SettingsCubit settingsCubit;

class SettingsCubit extends Cubit<SettingsState> {
  final StorageService _storageService;

  SettingsCubit(this._storageService, {required SettingsState initialState})
      : super(initialState) {
    settingsCubit = this;
  }

  static Future<SettingsCubit> initialize(StorageService storageService) async {
    String? homeWidgetSelectedListId = await storageService.getValue(
      'homeWidgetSelectedListId',
    );

    return SettingsCubit(
      storageService,
      initialState: SettingsState(
        closeToTray: await storageService.getValue('closeToTray') ?? true,
        homeWidgetSelectedListId: homeWidgetSelectedListId ?? '',
        logToFile: await storageService.getValue('logToFile') ?? false,
      ),
    );
  }

  Future<void> updateCloseToTray(bool value) async {
    emit(state.copyWith(closeToTray: value));
    await _storageService.saveValue(key: 'closeToTray', value: value);
  }

  Future<void> updateHomeWidgetSelectedListId(String id) async {
    emit(state.copyWith(homeWidgetSelectedListId: id));
    await _storageService.saveValue(key: 'homeWidgetSelectedListId', value: id);
  }

  Future<void> updateLogToFile(bool value) async {
    emit(state.copyWith(logToFile: value));
    await _storageService.saveValue(key: 'logToFile', value: value);
  }
}
