import 'package:intl/intl.dart';

extension DateTimeHelper on DateTime {
  /// Returns true if this date is the same as [other] (ignoring time).
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Returns a string representation of this date that is appropriate for
  /// displaying in the UI.
  ///
  /// If the task is due today, the label will be "Today, <TIME>".
  /// If the task is due tomorrow, the label will be "Tomorrow, <TIME>".
  ///
  /// If the task is due later than tomorrow, the label will be "<DATE>, <TIME>"
  /// (e.g. "Mon, Aug 2, 2021, 10:00 AM").
  ///
  /// If the task was due yesterday, the label will be "Yesterday, <TIME>".
  ///
  /// If the task was due earlier than yesterday, the label will be either "X days
  /// ago, <TIME>" or "X weeks ago, <TIME>".
  String toDueDateLabel() {
    final now = DateTime.now();

    String label;
    if (isSameDay(now)) {
      label = 'Today';
    } else if (isSameDay(now.add(const Duration(days: 1)))) {
      label = 'Tomorrow';
    } else if (isSameDay(now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else if (isBefore(now.subtract(const Duration(days: 1)))) {
      final daysAgo = now.difference(this).inDays;
      if (daysAgo < 7) {
        label = '$daysAgo days ago';
      } else if (daysAgo >= 7 && daysAgo < 14) {
        label = '1 week ago';
      } else {
        final weeksAgo = daysAgo ~/ 7;
        label = '$weeksAgo weeks ago';
      }
    } else {
      final formatter = DateFormat('EEE, MMM d');
      label = formatter.format(this);
    }

    final timeFormatter = DateFormat('h:mm a');
    // Time comes out like "10:00 a.m." and we want "10:00 AM".
    final String timeLabel = timeFormatter //
        .format(this)
        .replaceAll('.', '')
        .toUpperCase();

    return '$label, $timeLabel';
  }
}
