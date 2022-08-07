part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  /// The id of the list to show in the Android home widget / AppWidget.
  final String homeWidgetSelectedListId;

  final bool logToFile;

  final UpdateChannel updateChannel;

  const SettingsState({
    required this.homeWidgetSelectedListId,
    required this.logToFile,
    required this.updateChannel,
  });

  @override
  List<Object> get props => [
        homeWidgetSelectedListId,
        logToFile,
        updateChannel,
      ];

  SettingsState copyWith({
    String? homeWidgetSelectedListId,
    bool? logToFile,
    UpdateChannel? updateChannel,
  }) {
    return SettingsState(
      homeWidgetSelectedListId:
          homeWidgetSelectedListId ?? this.homeWidgetSelectedListId,
      logToFile: logToFile ?? this.logToFile,
      updateChannel: updateChannel ?? this.updateChannel,
    );
  }
}
