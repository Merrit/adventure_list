import 'package:adventure_list/src/tasks/tasks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrule/rrule.dart';

final DateTime now = DateTime.now().toUtc();

/// A default due date to reduce boilerplate.
final DateTime today = DateTime(
  now.year,
  now.month,
  now.day,
  // Default to 1 AM, so this should be today but in the past.
  1,
).toUtc();

void main() {
  group('RecurrenceRule:', () {
    group('nextInstance:', () {
      group('daily:', () {
        test('in the past returns instance for tomorrow', () {
          final DateTime dueDate = today.subtract(const Duration(days: 100));

          final RecurrenceRule rrule = RecurrenceRule(
            frequency: Frequency.daily,
            interval: 1,
          );

          final DateTime nextInstance = rrule.nextInstance(dueDate);
          expect(nextInstance, today.add(const Duration(days: 1)));
        });

        test('in the future returns instance for next day', () {
          final DateTime dueDate = today.add(const Duration(days: 100));

          final RecurrenceRule rrule = RecurrenceRule(
            frequency: Frequency.daily,
            interval: 1,
          );

          final DateTime nextInstance = rrule.nextInstance(dueDate);
          expect(nextInstance, dueDate.add(const Duration(days: 1)));
        });
      });
    });
  });
}
