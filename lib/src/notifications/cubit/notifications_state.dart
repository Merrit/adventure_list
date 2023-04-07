part of 'notifications_cubit.dart';

@freezed
class NotificationsState with _$NotificationsState {
  const factory NotificationsState({
    required bool enabled,
    NotificationResponse? notificationResponse,

    /// The number of overdue tasks.
    ///
    /// Tracked so we don't update the icons if the number hasn't changed.
    required int overdueTasksCount,
    required bool permissionGranted,
  }) = _NotificationsState;

  factory NotificationsState.initial() {
    return const NotificationsState(
      enabled: true,
      overdueTasksCount: 0,
      permissionGranted: false,
    );
  }
}
