import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:self_updater/self_updater.dart';

import '../../constants.dart';
import '../../settings/settings.dart';

part 'app_state.dart';

late final AppCubit appCubit;

class AppCubit extends Cubit<AppState> {
  final _log = Logger('AppCubit');

  AppCubit()
      : super(const AppState(
          appVersion: '',
          updateAvailable: false,
          updateVersion: '',
          updateInProgress: false,
        )) {
    appCubit = this;
    initialize();
  }

  Updater? _updater;

  Future<void> initialize() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    final File buildFile = File('BUILD');

    String currentVersion;
    if (await buildFile.exists()) {
      // Currently build file should only exist for Dev builds, which use the
      // time of build as their "version" for updates comparison sake.
      currentVersion = await buildFile.readAsString();
    } else {
      currentVersion = packageInfo.version;
    }

    final updater = await Updater.initialize(
      currentVersion: currentVersion,
      updateChannel: settingsCubit.state.updateChannel,
      repoUrl: kRepoUrl,
    );

    _updater = updater;

    emit(state.copyWith(
      appVersion: currentVersion,
      updateAvailable: updater.updateAvailable,
      updateVersion: updater.updateVersion,
    ));
  }

  Future<void> startUpdate() async {
    if (kDebugMode) return;

    assert(_updater != null);
    emit(state.copyWith(updateInProgress: true));
    _log.info('Beginning app update');

    // TODO: Should we download the update *before* prompting the user? Doing so
    // would negate the time required to download, not bother the user until a
    // successful download occurred in case of temporary issues, and make the
    // update appear essentially instant.
    final String? updateArchivePath = await _updater!.downloadUpdate();
    if (updateArchivePath == null) {
      _log.severe('Downloading update was NOT successful.');
      return;
    }

    await _updater!.installUpdate(
      archivePath: updateArchivePath,
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
