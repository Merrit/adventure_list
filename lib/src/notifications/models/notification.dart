import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';

/// A notification.
@freezed
class Notification with _$Notification {
  const factory Notification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) = _Notification;
}
