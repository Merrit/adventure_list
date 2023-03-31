import 'package:freezed_annotation/freezed_annotation.dart';

import 'models.dart';

part 'repeat_interval.freezed.dart';
part 'repeat_interval.g.dart';

/// Represents a repeat interval for a task.
///
/// This is used to determine when a task should be repeated.
///
/// For example, if the interval is set to 1 day, the task will be repeated
/// every day at the same time.
///
/// If the interval is set to 1 week, the task will be repeated every week at
/// the same time and day of the week.
///
/// If the interval is set to 1 month, the task will be repeated every month at
/// the same time and day of the month.
///
/// If the interval is set to 1 year, the task will be repeated every year at
/// the same time and day of the year.
///
/// If the interval is set to every 2 days, the task will be repeated every 2
/// days at the same time.
///
/// If the interval is set to every 2 weeks, the task will be repeated every 2
/// weeks at the same time and day of the week.
///
/// If the interval is set to every 2 months, the task will be repeated every 2
/// months at the same time and day of the month.
///
/// If the interval is set to every 2 years, the task will be repeated every 2
/// years at the same time and day of the year.
@freezed
class RepeatInterval with _$RepeatInterval {
  const factory RepeatInterval({
    /// The number of units between each repetition.
    required int count,

    /// The unit of time between each repetition.
    required RepeatIntervalUnit unit,
  }) = _RepeatInterval;

  factory RepeatInterval.fromJson(Map<String, dynamic> json) =>
      _$RepeatIntervalFromJson(json);
}
