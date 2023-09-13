import 'package:rrule/rrule.dart';

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
    final Iterable<DateTime> instances = getInstances(start: start.copyWith(isUtc: true));
    final DateTime nextDueDate = instances.first.copyWith(isUtc: false);

    return start.copyWith(
      year: nextDueDate.year,
      month: nextDueDate.month,
      day: nextDueDate.day,
    );
  }
}
