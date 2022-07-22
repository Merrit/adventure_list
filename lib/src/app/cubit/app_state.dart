part of 'app_cubit.dart';

class AppState extends Equatable {
  final String appVersion;
  final bool updateAvailable;
  final String updateVersion;
  final bool updateInProgress;

  const AppState({
    required this.appVersion,
    required this.updateAvailable,
    required this.updateVersion,
    required this.updateInProgress,
  });

  @override
  List<Object> get props => [
        appVersion,
        updateAvailable,
        updateVersion,
        updateInProgress,
      ];

  AppState copyWith({
    String? appVersion,
    bool? updateAvailable,
    String? updateVersion,
    bool? updateInProgress,
  }) {
    return AppState(
      appVersion: appVersion ?? this.appVersion,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      updateVersion: updateVersion ?? this.updateVersion,
      updateInProgress: updateInProgress ?? this.updateInProgress,
    );
  }
}
