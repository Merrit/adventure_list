part of 'app_cubit.dart';

class AppState extends Equatable {
  final String appVersion;
  final bool updateAutomatically;
  final bool updateAvailable;
  final bool updateDownloaded;
  final String updateVersion;
  final bool updateInProgress;

  const AppState({
    required this.appVersion,
    required this.updateAutomatically,
    required this.updateAvailable,
    required this.updateDownloaded,
    required this.updateVersion,
    required this.updateInProgress,
  });

  @override
  List<Object> get props {
    return [
      appVersion,
      updateAutomatically,
      updateAvailable,
      updateDownloaded,
      updateVersion,
      updateInProgress,
    ];
  }

  AppState copyWith({
    String? appVersion,
    bool? updateAutomatically,
    bool? updateAvailable,
    bool? updateDownloaded,
    String? updateVersion,
    bool? updateInProgress,
  }) {
    return AppState(
      appVersion: appVersion ?? this.appVersion,
      updateAutomatically: updateAutomatically ?? this.updateAutomatically,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      updateDownloaded: updateDownloaded ?? this.updateDownloaded,
      updateVersion: updateVersion ?? this.updateVersion,
      updateInProgress: updateInProgress ?? this.updateInProgress,
    );
  }
}
