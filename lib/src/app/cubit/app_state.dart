part of 'app_cubit.dart';

@freezed
class AppState with _$AppState {
  const factory AppState({
    /// True if this is the first run of the app.
    required bool firstRun,
    required String runningVersion,
    required String? updateVersion,
    required bool updateAvailable,
    required bool showUpdateButton,

    /// True if a condition has been met requiring the user to be
    /// prompted to purchase the pro upgrade.
    required bool promptForProUpgrade,

    /// Release notes for the current version.
    required ReleaseNotes? releaseNotes,
  }) = _AppState;

  factory AppState.initial() {
    return const AppState(
      firstRun: false,
      runningVersion: '',
      updateVersion: null,
      updateAvailable: false,
      showUpdateButton: false,
      promptForProUpgrade: false,
      releaseNotes: null,
    );
  }
}
