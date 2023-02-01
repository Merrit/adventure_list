import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> initialize({required SettingsCubit settingsCubit}) async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    logger.v('Current version: $currentVersion');

    emit(state.copyWith(
      appVersion: currentVersion,
    ));
  }

  Future<bool> launchAUrl(Uri url) async {
    return await launchUrl(url);
  }
}
