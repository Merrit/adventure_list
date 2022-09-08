part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final bool closeToTray;

  /// The id of the list to show in the Android home widget / AppWidget.
  final String homeWidgetSelectedListId;

  final bool logToFile;
  final bool updateAutomatically;
  final UpdateChannel updateChannel;

  const SettingsState({
    required this.closeToTray,
    required this.homeWidgetSelectedListId,
    required this.logToFile,
    required this.updateAutomatically,
    required this.updateChannel,
  });

  @override
  List<Object> get props {
    return [
      closeToTray,
      homeWidgetSelectedListId,
      logToFile,
      updateAutomatically,
      updateChannel,
    ];
  }

  SettingsState copyWith({
    bool? closeToTray,
    String? homeWidgetSelectedListId,
    bool? logToFile,
    bool? updateAutomatically,
    UpdateChannel? updateChannel,
  }) {
    return SettingsState(
      closeToTray: closeToTray ?? this.closeToTray,
      homeWidgetSelectedListId:
          homeWidgetSelectedListId ?? this.homeWidgetSelectedListId,
      logToFile: logToFile ?? this.logToFile,
      updateAutomatically: updateAutomatically ?? this.updateAutomatically,
      updateChannel: updateChannel ?? this.updateChannel,
    );
  }
}
