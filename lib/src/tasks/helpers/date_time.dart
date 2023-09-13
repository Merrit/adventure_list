import 'package:intl/intl.dart';

extension DateTimeHelper on DateTime {
  /// Returns a DateTime for today at 8:00 AM, in UTC.
  static DateTime today() {
    final now = DateTime.now().copyWith(hour: 8, minute: 0, second: 0, millisecond: 0);
    return DateTime(now.year, now.month, now.day, now.hour).toUtc();
  }

  /// Returns the given [DateTime] as a string representing the date of the recurrence.
  ///
  /// If in the current year, the string will be formatted like "August 18".
  ///
  /// If in a different year, the string will be formatted as "Aug 18, 2021".
  String toRecurrenceLabel() {
    final now = DateTime.now();

    final DateFormat formatter =
        (now.year == year) ? DateFormat.MMMMd() : DateFormat('MMM d, yyyy');

    return formatter.format(this);
  }

  /// Returns the given [DateTime] as a string representing the time of the recurrence.
  ///
  /// The string will be formatted like "8:00 AM".
  String toTimeLabel() {
    final DateFormat formatter = DateFormat.jm();

    String formatted = formatter.format(this);

    /// `format()` is returning with unicode character U+202F (narrow no-break space) instead of
    /// regular space. This is causing the test to fail.
    ///
    /// This is a workaround to replace the unicode character with a regular space.
    ///
    /// See:
    /// https://github.com/dart-lang/i18n/issues/711
    formatted = formatted.replaceAll('\u202F', ' ');
    return formatted;
  }
}
