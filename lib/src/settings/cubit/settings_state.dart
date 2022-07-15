part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final String homeWidgetSelectedListId;

  const SettingsState({
    required this.homeWidgetSelectedListId,
  });

  @override
  List<Object> get props => [homeWidgetSelectedListId];

  SettingsState copyWith({
    String? homeWidgetSelectedListId,
  }) {
    return SettingsState(
      homeWidgetSelectedListId:
          homeWidgetSelectedListId ?? this.homeWidgetSelectedListId,
    );
  }
}
