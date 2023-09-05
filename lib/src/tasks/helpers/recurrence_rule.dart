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
}
