import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide RepeatInterval;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../core/core.dart';
import '../../logs/logging_manager.dart';
import '../../tasks/tasks.dart';
import '../../window/app_window.dart';

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
    actions: [
      LinuxNotificationAction(
        key: 'complete',
        label: 'Complete',
      ),
      LinuxNotificationAction(
        key: 'snooze',
        label: 'Snooze',
      ),
    ],
    category: LinuxNotificationCategory('adventurelist'),
    defaultActionName: 'Open notification',
    urgency: LinuxNotificationUrgency.critical,
  );

  /// Notification timers.
  ///
  /// This is a map of task ids to timers. The timers are used to schedule
  /// notifications for tasks on desktop.
  final _timers = <String, Timer>{};

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

  /// Schedule a notification for a task.
  ///
  /// This will only schedule a notification if notifications are enabled and
  /// permission has been granted.
  Future<void> scheduleNotification(Task task) async {
    log.v('Scheduling notification for task: ${task.id}');

    if (!state.enabled) {
      log.v('Notifications are disabled. Not scheduling notification.');
      return;
    }

    if (!state.permissionGranted) {
      await _requestPermission();
      if (!state.permissionGranted) {
        log.v(
          'Notifications permission not granted. Not scheduling notification.',
        );
        return;
      }
    }

    if (defaultTargetPlatform.isDesktop) {
      await _scheduleNotificationDesktop(task);
    } else {
      await _scheduleNotificationMobile(task);
    }
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

    id ??= _generateNotificationId();

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

  /// Generate a random id for a notification.
  ///
  /// The id will fit within a 32-bit integer as required by the plugin.
  int _generateNotificationId() {
    return Random().nextInt(1 << 30);
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

  /// Schedule a notification on desktop.
  ///
  /// This will create a timer that will show the notification when the timer
  /// expires.
  Future<void> _scheduleNotificationDesktop(Task task) async {
    log.v('Scheduling notification for task: ${task.id}');

    if (!state.enabled) {
      log.v('Notifications are disabled. Not scheduling notification.');
      return;
    }

    final dueDate = task.dueDate;
    if (dueDate == null) {
      log.v('Task has no due date. Not scheduling notification.');
      return;
    }

    // If the task is already overdue, show the notification immediately.
    if (dueDate.isBefore(DateTime.now())) {
      log.v('Task is already overdue. Showing notification immediately.');
      await showNotification(
        title: task.title,
        body: 'This task is overdue.',
        payload: jsonEncode(task.toJson()),
      );
      return;
    }

    final timer = Timer(
      dueDate.difference(DateTime.now()),
      () async {
        log.v('Showing scheduled notification for task: ${task.id}');
        await showNotification(
          id: task.notificationId,
          title: task.title,
          body: '',
          payload: jsonEncode(task.toJson()),
        );
      },
    );

    _timers[task.id] = timer;
    log.v('Scheduled notification for task: ${task.id}');
  }

  /// Schedule a notification on mobile.
  ///
  /// This will register a notification with the OS.
  Future<void> _scheduleNotificationMobile(Task task) async {
    log.v('Scheduling notification for task: ${task.id}');

    if (!state.enabled) {
      log.v('Notifications are disabled. Not scheduling notification.');
      return;
    }

    final dueDate = task.dueDate;
    if (dueDate == null) {
      log.v('Task has no due date. Not scheduling notification.');
      return;
    }

    // If the task is already overdue, show the notification immediately.
    if (dueDate.isBefore(DateTime.now())) {
      log.v('Task is already overdue. Showing notification immediately.');
      await showNotification(
        id: task.notificationId,
        title: task.title,
        body: 'This task is overdue.',
        payload: jsonEncode(task.toJson()),
      );
      return;
    }

    await _scheduleNotificationWithSystem(
      title: task.title,
      body: '',
      scheduledDate: dueDate,
      payload: jsonEncode(task.toJson()),
    );
  }

  /// Schedule a notification with the host OS.
  ///
  /// [id] is a unique identifier for the notification. If not specified, a
  /// random id will be generated. The id must fit within a 32-bit integer.
  ///
  /// [scheduledDate] is the date and time the notification should be shown.
  ///
  /// [payload] is an optional string that will be passed to the app when the
  /// notification is tapped.
  Future<void> _scheduleNotificationWithSystem({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    log.v('Scheduling notification: $title');

    const notificationDetails = NotificationDetails(
      android: _androidNotificationDetails,
      iOS: _iOSNotificationDetails,
      macOS: _macOSNotificationDetails,
      linux: _linuxNotificationDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
}

/// A stream that emits a notification response when the user taps on a
/// notification.
final StreamController<NotificationResponse> notificationResponseStream =
    StreamController.broadcast();

/// Handle background notification actions.
///
/// This is called when the user taps on a notification action button.
///
/// On all platforms except Linux this runs in a separate isolate.
@pragma('vm:entry-point')
void _notificationBackgroundCallback(NotificationResponse response) {
  throw UnimplementedError();
}

/// Called when the user taps on a notification.
Future<void> _notificationCallback(NotificationResponse response) async {
  if (defaultTargetPlatform.isDesktop) {
    // On desktop, the app is already running so we can just show the window.
    await AppWindow.instance.show();
    await AppWindow.instance.focus();
  }

  // response.payload is the id of the task.
  switch (response.notificationResponseType) {
    case NotificationResponseType.selectedNotification:
      notificationResponseStream.add(response);
      break;
    case NotificationResponseType.selectedNotificationAction:
      // response.actionId will be either `complete` or `snooze`.
      notificationResponseStream.add(response);
      break;
  }
}
