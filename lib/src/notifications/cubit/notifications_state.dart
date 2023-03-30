part of 'notifications_cubit.dart';

@freezed
class NotificationsState with _$NotificationsState {
  const factory NotificationsState({
    required bool enabled,
    NotificationResponse? notificationResponse,
    required bool permissionGranted,
  }) = _NotificationsState;

  factory NotificationsState.initial() {
    return const NotificationsState(
      enabled: true,
      permissionGranted: false,
    );
  }
}
