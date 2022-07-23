import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:self_updater/self_updater.dart';

import '../../app/cubit/app_cubit.dart';
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

    String? updateChannelString = await storageService.getValue(
      'updateChannel',
    );
    UpdateChannel updateChannel;
    if (updateChannelString == null) {
      updateChannel = UpdateChannel.stable;
    } else {
      updateChannel = UpdateChannel.values.byName(updateChannelString);
    }

    return SettingsCubit(
      storageService,
      initialState: SettingsState(
        homeWidgetSelectedListId: homeWidgetSelectedListId ?? '',
        updateChannel: updateChannel,
      ),
    );
  }

  Future<void> updateHomeWidgetSelectedListId(String id) async {
    emit(state.copyWith(homeWidgetSelectedListId: id));
    await _storageService.saveValue(key: 'homeWidgetSelectedListId', value: id);
  }

  Future<void> setUpdateChannel(UpdateChannel? channel) async {
    if (channel == null) return;

    emit(state.copyWith(updateChannel: channel));
    await _storageService.saveValue(key: 'updateChannel', value: channel.name);
    appCubit.setUpdateChannel(channel);
  }
}
