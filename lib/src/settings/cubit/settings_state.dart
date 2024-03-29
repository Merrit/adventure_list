part of 'settings_cubit.dart';

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    /// True if the app should be automatically started on login.
    ///
    /// This is only used on desktop platforms.
    required bool autostart,

    /// True if the app should be closed to the system tray instead of exiting.
    required bool closeToTray,

    /// The settings for the desktop widget.
    required DesktopWidgetSettings desktopWidgetSettings,

    /// The id of the list to show in the Android home widget / AppWidget.
    required String homeWidgetSelectedListId,

    /// The theme to use.
    required ThemeData theme,
  }) = _SettingsState;
}
