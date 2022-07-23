part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  /// The id of the list to show in the Android home widget / AppWidget.
  final String homeWidgetSelectedListId;

  final UpdateChannel updateChannel;

  const SettingsState({
    required this.homeWidgetSelectedListId,
    required this.updateChannel,
  });

  @override
  List<Object> get props => [homeWidgetSelectedListId, updateChannel];

  SettingsState copyWith({
    String? homeWidgetSelectedListId,
    UpdateChannel? updateChannel,
  }) {
    return SettingsState(
      homeWidgetSelectedListId:
          homeWidgetSelectedListId ?? this.homeWidgetSelectedListId,
      updateChannel: updateChannel ?? this.updateChannel,
    );
  }
}
