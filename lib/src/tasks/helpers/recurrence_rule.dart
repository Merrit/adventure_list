import 'package:rrule/rrule.dart';

import '../../core/helpers/helpers.dart';
import '../enums/enums.dart';

extension RecurrenceRuleHelper on RecurrenceRule {
  /// Returns the [RecurrenceEndType] of the [RecurrenceRule].
  RecurrenceEndType get endType {
    if (count != null) {
      return RecurrenceEndType.afterOccurrences;
    } else if (until != null) {
      return RecurrenceEndType.onDate;
    } else {
      return RecurrenceEndType.never;
    }
  }

  /// Returns the next instance date of the [RecurrenceRule] after [start].
  DateTime nextInstance(DateTime start) {
    final DateTime now = DateTime.now().toUtc();

    final Iterable<DateTime> instances = getInstances(start: now);
    final DateTime nextDueDate = instances.firstWhere(
      (DateTime instance) =>
          instance.isAfter(start) && instance.isAfter(now) && !instance.isSameDay(start),
    );

    return start.copyWith(
      year: nextDueDate.year,
      month: nextDueDate.month,
      day: nextDueDate.day,
    );
  }
}
