import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:self_updater/self_updater.dart';

import '../../constants.dart';
import '../../logs/logs.dart';
import '../../settings/settings.dart';

part 'app_state.dart';

late final AppCubit appCubit;

class AppCubit extends Cubit<AppState> {
  AppCubit(SettingsCubit settingsCubit)
      : super(const AppState(
          appVersion: '',
          updateAutomatically: false,
          updateAvailable: false,
          updateDownloaded: false,
          updateVersion: '',
          updateInProgress: false,
        )) {
    appCubit = this;
    initialize(settingsCubit: settingsCubit);
  }

  Updater? _updater;

  Future<void> initialize({required SettingsCubit settingsCubit}) async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    final File buildFile = File(
      '${applicationDirectory.path}${Platform.pathSeparator}BUILD',
    );
    final bool buildFileExists = await buildFile.exists();

    String currentVersion;
    if (buildFileExists) {
      // Currently build file should only exist for Dev builds, which use the
      // time of build as their "version" for updates comparison sake.
      currentVersion = await buildFile.readAsString();
    } else {
      currentVersion = packageInfo.version;
    }

    logger.i('''
BUILD file path would be: ${buildFile.path}
build file exists: $buildFileExists
current version: $currentVersion''');

    final updater = await Updater.initialize(
      currentVersion: currentVersion,
      updateChannel: settingsCubit.state.updateChannel,
      repoUrl: kRepoUrl,
    );

    _updater = updater;

    emit(state.copyWith(
      appVersion: currentVersion,
      updateAutomatically: settingsCubit.state.updateAutomatically,
      updateAvailable: updater.updateAvailable,
      updateVersion: updater.updateVersion,
    ));

    if (settingsCubit.state.updateAutomatically) downloadUpdate();
  }

  String? updateArchivePath;

  Future<void> downloadUpdate() async {
    if (kDebugMode) return;
    assert(_updater != null);
    if (!state.updateAvailable) return;

    logger.i('Downloading update.');
    emit(state.copyWith(updateInProgress: true));

    updateArchivePath = await _updater!.downloadUpdate();
    if (updateArchivePath == null) {
      logger.e('Downloading update was NOT successful.');
      return;
    }

    emit(state.copyWith(updateDownloaded: true, updateInProgress: false));
  }

  Future<void> startUpdate() async {
    if (kDebugMode) return;
    assert(_updater != null);
    if (updateArchivePath == null) {
      logger.e('Update archive path is null!');
      return;
    }

    logger.i('Installing app update.');
    emit(state.copyWith(updateInProgress: true));

    await _updater!.installUpdate(
      archivePath: updateArchivePath!,
      relaunchApp: true,
    );

    emit(state.copyWith(updateInProgress: false));
  }

  Future<void> setUpdateChannel(UpdateChannel updateChannel) async {
    final updater = await Updater.initialize(
      currentVersion: state.appVersion,
      updateChannel: updateChannel,
      repoUrl: kRepoUrl,
    );

    _updater = updater;

    emit(state.copyWith(
      updateAvailable: updater.updateAvailable,
      updateVersion: updater.updateVersion,
    ));
  }
}
