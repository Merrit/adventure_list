import 'package:rrule/rrule.dart';

extension FrequencyHelper on Frequency {
  String toText(bool plural) {
    switch (this) {
      case Frequency.daily:
        return plural ? 'days' : 'day';
      case Frequency.weekly:
        return plural ? 'weeks' : 'week';
      case Frequency.monthly:
        return plural ? 'months' : 'month';
      case Frequency.yearly:
        return plural ? 'years' : 'year';
      default:
        return '';
    }
  }
}
