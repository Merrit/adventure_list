import 'package:rrule/rrule.dart';

class RecurrenceRuleService {
  /// The RecurrenceRule translations.
  ///
  /// Initialized by [ensureInitialized] so the translations are available
  /// without requiring repeated async calls.
  ///
  /// The rrule package only supports English at the moment.
  static late RruleL10n recurrenceRuleL10n;

  const RecurrenceRuleService._();

  static Future<void> ensureInitialized() async {
    recurrenceRuleL10n = await RruleL10nEn.create();
  }
}
