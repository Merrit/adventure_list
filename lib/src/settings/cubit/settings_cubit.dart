import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../storage/storage_service.dart';

part 'settings_state.dart';

late final SettingsCubit settingsCubit;

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required SettingsState initialState}) : super(initialState) {
    settingsCubit = this;
  }

  static Future<SettingsCubit> initialize() async {
    String? homeWidgetSelectedListId = await StorageService.instance.getValue(
      'homeWidgetSelectedListId',
    );

    return SettingsCubit(
      initialState: SettingsState(
        closeToTray:
            await StorageService.instance.getValue('closeToTray') ?? true,
        homeWidgetSelectedListId: homeWidgetSelectedListId ?? '',
      ),
    );
  }

  Future<void> updateCloseToTray(bool value) async {
    emit(state.copyWith(closeToTray: value));
    await StorageService.instance.saveValue(
      key: 'closeToTray',
      value: value,
    );
  }

  Future<void> updateHomeWidgetSelectedListId(String id) async {
    emit(state.copyWith(homeWidgetSelectedListId: id));
    await StorageService.instance.saveValue(
      key: 'homeWidgetSelectedListId',
      value: id,
    );
  }
}
