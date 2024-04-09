part of 'notifications_cubit.dart';

@freezed
class NotificationsState with _$NotificationsState {
  const factory NotificationsState({
    required bool enabled,
    NotificationResponse? notificationResponse,

    /// Whether the app has permission to show exact notifications.
    required bool notificationExactPermissionGranted,

    /// Whether the app has permission to show notifications.
    required bool notificationPermissionGranted,

    /// The number of overdue tasks.
    ///
    /// Tracked so we don't update the icons if the number hasn't changed.
    required int overdueTasksCount,
  }) = _NotificationsState;

  factory NotificationsState.initial() {
    return const NotificationsState(
      enabled: true,
      notificationExactPermissionGranted: false,
      notificationPermissionGranted: false,
      overdueTasksCount: 0,
    );
  }
}
