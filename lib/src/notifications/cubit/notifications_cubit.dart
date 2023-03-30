import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../core/core.dart';
import '../../logs/logging_manager.dart';

part 'notifications_state.dart';
part 'notifications_cubit.freezed.dart';

/// Cubit for managing notifications.
class NotificationsCubit extends Cubit<NotificationsState> {
  /// Plugin instance.
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  NotificationsCubit._(
    this._notificationsPlugin,
  ) : super(NotificationsState.initial()) {
    instance = this;
    _checkAppStartup();
  }

  /// Singleton instance.
  static late NotificationsCubit instance;

  /// Initialize the cubit.
  static Future<NotificationsCubit> initialize({
    required FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  }) async {
    tz.initializeTimeZones();
    final localTimeZoneName = tz.local.name;
    tz.setLocalLocation(tz.getLocation(localTimeZoneName));

    const initSettingsAndroid = AndroidInitializationSettings('app_icon');
    const initSettingsDarwin = DarwinInitializationSettings();
    final initSettingsLinux = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
      defaultIcon: AssetsLinuxIcon(
        'assets/icons/codes.merritt.adventurelist.svg',
      ),
    );

    final initSettings = InitializationSettings(
        android: initSettingsAndroid,
        iOS: initSettingsDarwin,
        macOS: initSettingsDarwin,
        linux: initSettingsLinux);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveBackgroundNotificationResponse:
          _notificationBackgroundCallback,
      onDidReceiveNotificationResponse: _notificationCallback,
    );

    return NotificationsCubit._(
      flutterLocalNotificationsPlugin,
    );
  }

  static const _androidNotificationDetails = AndroidNotificationDetails(
    kPackageId,
    'App notifications',
    importance: Importance.max,
    priority: Priority.high,
    styleInformation: DefaultStyleInformation(true, true),
  );

  static const _iOSNotificationDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const _macOSNotificationDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const _linuxNotificationDetails = LinuxNotificationDetails(
    defaultActionName: 'Open notification',
  );

  /// Disable notifications.
  ///
  /// This will also cancel all scheduled notifications.
  Future<void> disable() async {
    await _notificationsPlugin.cancelAll();
    emit(state.copyWith(enabled: false));
  }

  /// Enable notifications.
  Future<void> enable() async {
    emit(state.copyWith(enabled: true));
  }

  /// Show a notification.
  ///
  /// This will only show a notification if notifications are enabled and
  /// permission has been granted.
  ///
  /// [id] is a unique identifier for the notification. If not specified, a
  /// random id will be generated. The id must fit within a 32-bit integer.
  Future<void> showNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
  }) async {
    log.v('Showing notification: $title, $body, $payload');

    if (!state.enabled) {
      log.v('Notifications are disabled. Not showing notification.');
      return;
    }

    if (!state.permissionGranted) {
      await _requestPermission();
      if (!state.permissionGranted) {
        log.v(
          'Notifications permission not granted. Not showing notification.',
        );
        return;
      }
    }

    // Generate a random id if one is not provided.
    //
    // Ensure it fits within a 32-bit integer as required by the plugin.
    id ??= DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF;

    const notificationDetails = NotificationDetails(
      android: _androidNotificationDetails,
      iOS: _iOSNotificationDetails,
      macOS: _macOSNotificationDetails,
      linux: _linuxNotificationDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Check if the app was started from a notification.
  ///
  /// If so, emit state so we can navigate to the correct screen.
  Future<void> _checkAppStartup() async {
    // Currently only supported on Android.
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final appLaunchDetails = await _notificationsPlugin //
        .getNotificationAppLaunchDetails();

    final notificationResponse = appLaunchDetails?.notificationResponse;

    if (appLaunchDetails == null ||
        !appLaunchDetails.didNotificationLaunchApp ||
        notificationResponse == null) {
      return;
    }

    log.i('App started from notification');

    emit(state.copyWith(
      notificationResponse: notificationResponse,
    ));
  }

  /// Called when the user taps on a notification.
  static Future<void> _notificationCallback(
    NotificationResponse response,
  ) async {
    log.i('notificationCallback:\n'
        'id: ${response.id}\n'
        'actionId: ${response.actionId}\n'
        'input: ${response.input}\n'
        'payload: ${response.payload}\n'
        'notificationResponseType: ${response.notificationResponseType}');
  }

  /// Request permission to show notifications.
  Future<void> _requestPermission() async {
    // Currently only Android requires permission.
    if (defaultTargetPlatform != TargetPlatform.android) {
      emit(state.copyWith(permissionGranted: true));
      return;
    }

    final androidPlugin = _notificationsPlugin //
        .resolvePlatformSpecificImplementation //
        <AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    final bool? permissionGranted = await androidPlugin.requestPermission();
    if (permissionGranted == null) return;

    if (permissionGranted) {
      log.i('Notifications permission granted');
    } else {
      log.i('Notifications permission denied');
    }

    emit(state.copyWith(permissionGranted: permissionGranted));
  }
}

/// Handle background notification actions.
///
/// This is called when the user taps on a notification action button.
///
/// On all platforms except Linux this runs in a separate isolate.
@pragma('vm:entry-point')
void _notificationBackgroundCallback(NotificationResponse response) {
  log.i('notificationBackgroundCallback');
}
