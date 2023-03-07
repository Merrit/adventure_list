import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../storage/storage_repository.dart';

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
      ),
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
}
