import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:self_updater/self_updater.dart';

import '../../constants.dart';
import '../../settings/settings.dart';

part 'app_state.dart';

late final AppCubit appCubit;

class AppCubit extends Cubit<AppState> {
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
    emit(state.copyWith(updateInProgress: true));
    await Future.delayed(const Duration(seconds: 5));
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
