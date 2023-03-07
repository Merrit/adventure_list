part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final bool closeToTray;

  /// The id of the list to show in the Android home widget / AppWidget.
  final String homeWidgetSelectedListId;

  final ThemeData theme;

  const SettingsState({
    required this.closeToTray,
    required this.homeWidgetSelectedListId,
    required this.theme,
  });

  @override
  List<Object> get props {
    return [
      closeToTray,
      homeWidgetSelectedListId,
      theme,
    ];
  }

  SettingsState copyWith({
    bool? closeToTray,
    String? homeWidgetSelectedListId,
    bool? logToFile,
    ThemeData? theme,
  }) {
    return SettingsState(
      closeToTray: closeToTray ?? this.closeToTray,
      homeWidgetSelectedListId:
          homeWidgetSelectedListId ?? this.homeWidgetSelectedListId,
      theme: theme ?? this.theme,
    );
  }
}
