part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final bool closeToTray;

  /// The id of the list to show in the Android home widget / AppWidget.
  final String homeWidgetSelectedListId;

  final bool logToFile;

  const SettingsState({
    required this.closeToTray,
    required this.homeWidgetSelectedListId,
    required this.logToFile,
  });

  @override
  List<Object> get props {
    return [
      closeToTray,
      homeWidgetSelectedListId,
      logToFile,
    ];
  }

  SettingsState copyWith({
    bool? closeToTray,
    String? homeWidgetSelectedListId,
    bool? logToFile,
  }) {
    return SettingsState(
      closeToTray: closeToTray ?? this.closeToTray,
      homeWidgetSelectedListId:
          homeWidgetSelectedListId ?? this.homeWidgetSelectedListId,
      logToFile: logToFile ?? this.logToFile,
    );
  }
}
