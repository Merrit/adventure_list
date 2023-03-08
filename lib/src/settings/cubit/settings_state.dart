part of 'settings_cubit.dart';

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    required bool closeToTray,

    /// The id of the list to show in the Android home widget / AppWidget.
    required String homeWidgetSelectedListId,
    required ThemeData theme,
  }) = _SettingsState;
}
