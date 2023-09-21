import 'package:adventure_list/src/tasks/tasks.dart';
import 'package:adventure_list/src/tasks/widgets/task_details/task_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rrule/rrule.dart';

@GenerateNiceMocks([
  MockSpec<TasksCubit>(),
])
import 'recurrence_widget_test.mocks.dart';

/// Today's date at 8 AM.
final DateTime today = DateTime.now()
    .copyWith(
      hour: 8,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    )
    .toUtc();

/// Tomorrow's date at 8 AM.
final DateTime tomorrow = today.add(const Duration(days: 1));

final initialTask = Task(
  id: '1',
  index: 0,
  title: 'Task 1',
  description: 'Task 1 description',
  recurrenceRule: RecurrenceRule(
    frequency: Frequency.daily,
    interval: 1,
  ),
  taskListId: '1',
);

final initialTaskList = TaskList(
  id: '1',
  index: 0,
  title: 'Task List 1',
  items: [
    initialTask,
  ],
);

final initialTasksState = TasksState.initial().copyWith(
  loading: false,
  taskLists: [
    initialTaskList,
  ],
  activeList: initialTaskList,
  activeTask: initialTask,
);

MockTasksCubit mockTasksCubit = MockTasksCubit();

/// The icon to switch to the next month in the Material date picker.
final Finder nextMonthIcon = find.byWidgetPredicate(
    (Widget w) => w is IconButton && (w.tooltip?.startsWith('Next month') ?? false));

/// The button to select the recurrence type, e.g. daily, weekly, monthly, etc.
final Finder recurrenceTypeButton = find.byType(DropdownButtonFormField<Frequency>);

void main() {
  setUpAll(() async {
    await RecurrenceRuleService.ensureInitialized();
  });

  group('RecurrenceWidget:', () {
    setUp(() {
      reset(mockTasksCubit);
      when(mockTasksCubit.state).thenReturn(initialTasksState);
    });

    testWidgets('tile in task details renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(_buildRecurrenceWidget());
      expect(find.text('Repeat'), findsOneWidget);
    });

    testWidgets('tapped tile shows recurrence dialog', (WidgetTester tester) async {
      await tester.pumpWidget(_buildRecurrenceWidget());
      await tester.tap(find.text('Repeat'));
      await tester.pumpAndSettle();

      expect(find.text('Repeats every'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('day'), findsOneWidget);
      expect(find.text('8:00 AM'), findsOneWidget);
      expect(find.text('Starts'), findsOneWidget);
      expect(find.text('Ends'), findsOneWidget);
      expect(find.text('Never'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);
      expect(find.text('After'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('tapping cancel closes dialog with no changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildRecurrenceWidget());
      await tester.tap(find.text('Repeat'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Repeats every'), findsNothing);
      verifyNever(mockTasksCubit.updateTask(any));
    });

    group('daily:', () {
      testWidgets('every day', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final expectedTask = initialTask.copyWith(
          dueDate: tomorrow,
          recurrenceRule: RecurrenceRule(
            frequency: Frequency.daily,
            interval: 1,
          ),
        );

        when(mockTasksCubit.updateTask(any)).thenAnswer((invokation) async {
          final task = invokation.positionalArguments[0] as Task;
          return task;
        });

        expect(verify(mockTasksCubit.updateTask(captureAny)).captured, [expectedTask]);
      });

      testWidgets('every 2 days', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();

        await tester.enterText(find.text('1'), '2');

        final DateTime expectedDueDate;
        if (DateTime.now().isAfter(today)) {
          expectedDueDate = today.add(const Duration(days: 1));
        } else {
          expectedDueDate = today;
        }

        final expectedTask = initialTask.copyWith(
          dueDate: expectedDueDate,
          recurrenceRule: RecurrenceRule(
            frequency: Frequency.daily,
            interval: 2,
          ),
        );

        when(mockTasksCubit.updateTask(any)).thenAnswer((invokation) async {
          final task = invokation.positionalArguments[0] as Task;
          return task;
        });

        await tester.tap(find.text('Save'));

        expect(verify(mockTasksCubit.updateTask(captureAny)).captured, [expectedTask]);
      });

      testWidgets('custom time', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('8:00 AM'));
        await tester.pumpAndSettle();

        /// There is no way to tap on the time picker dial, so we have to tap
        /// on the screen at the desired location.
        ///
        /// This is a nasty hack, but it works and the time picker doesn't appear to
        /// support a better way at the moment.
        ///
        /// See:
        /// https://stackoverflow.com/a/65775466/9872288
        final center = tester.getCenter(
          find.byKey(const ValueKey<String>('time-picker-dial')),
        );

        await tester.tapAt(Offset(center.dx - 10, center.dy));

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.text('9:00 AM'), findsOneWidget);

        final DateTime expectedDate = tomorrow.add(const Duration(hours: 1));

        final expectedTask = initialTask.copyWith(
          dueDate: expectedDate,
          recurrenceRule: RecurrenceRule(
            frequency: Frequency.daily,
            interval: 1,
          ),
        );

        when(mockTasksCubit.updateTask(captureAny)).thenAnswer((invokation) async {
          final task = invokation.positionalArguments[0] as Task;
          return task;
        });

        await tester.tap(find.text('Save'));

        expect(verify(mockTasksCubit.updateTask(captureAny)).captured, [expectedTask]);
      });

      testWidgets('custom start date', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.text(today.add(const Duration(days: 1)).toRecurrenceLabel()),
        );
        await tester.pumpAndSettle();

        await tester.tap(nextMonthIcon);
        await tester.pumpAndSettle();

        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        final int nextMonth = DateTime.now().add(const Duration(days: 30)).month;
        final String nextMonthString = nextMonth.toMonthString();

        expect(find.text('$nextMonthString 15'), findsOneWidget);

        final expectedTask = initialTask.copyWith(
          dueDate: today.toLocal().copyWith(month: nextMonth, day: 15).toUtc(),
          recurrenceRule: RecurrenceRule(
            frequency: Frequency.daily,
            interval: 1,
          ),
        );

        when(mockTasksCubit.updateTask(captureAny)).thenAnswer((invokation) async {
          final task = invokation.positionalArguments[0] as Task;
          return task;
        });

        await tester.tap(find.text('Save'));

        expect(verify(mockTasksCubit.updateTask(captureAny)).captured, [expectedTask]);
      });

      testWidgets('ends on', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('recurrenceEndsOnDateButton')));
        await tester.pumpAndSettle();

        await tester.tap(nextMonthIcon);
        await tester.pumpAndSettle();

        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        final int twoMonthsFromNow = DateTime.now().add(const Duration(days: 60)).month;
        final String twoMonthsFromNowString = twoMonthsFromNow.toMonthString();

        expect(find.text('$twoMonthsFromNowString 15'), findsOneWidget);

        final expectedTask = initialTask.copyWith(
          dueDate: tomorrow,
          recurrenceRule: RecurrenceRule(
            frequency: Frequency.daily,
            interval: 1,
            until: today.toLocal().copyWith(month: twoMonthsFromNow, day: 15).toUtc(),
          ),
        );

        when(mockTasksCubit.updateTask(captureAny)).thenAnswer((invokation) async {
          final task = invokation.positionalArguments[0] as Task;
          return task;
        });

        await tester.tap(find.text('Save'));

        expect(verify(mockTasksCubit.updateTask(captureAny)).captured, [expectedTask]);
      });

      testWidgets('ends after', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();

        /// Scroll the widget into view since it is at the bottom of the screen.
        ///
        /// Scrolling a SingleChildScrollView is a bit tricky.
        ///
        /// See:
        /// https://github.com/flutter/flutter/issues/76981#issuecomment-1668250616
        final scrollable = find.descendant(
          of: find.byKey(const Key('singleChildScrollView')),
          matching: find.byType(Scrollable).at(0),
        );
        await tester.scrollUntilVisible(
          find.byKey(const Key('recurrenceEndsAfterTextField')),
          100,
          scrollable: scrollable,
        );

        await tester.tap(find.byKey(const Key('recurrenceEndsAfterTextField')));
        await tester.pumpAndSettle();

        await tester.enterText(find.text('30'), '12');
        await tester.tap(find.text('Save'));

        final Finder recurrenceEndsAfterTextField = find.byWidgetPredicate((widget) =>
            widget is TextField &&
            widget.controller?.text.trim() == '12' &&
            widget.decoration?.suffixText == 'times');
        expect(recurrenceEndsAfterTextField, findsOneWidget);

        final expectedTask = initialTask.copyWith(
          dueDate: tomorrow,
          recurrenceRule: RecurrenceRule(
            frequency: Frequency.daily,
            interval: 1,
            count: 12,
          ),
        );

        when(mockTasksCubit.updateTask(captureAny)).thenAnswer((invokation) async {
          final task = invokation.positionalArguments[0] as Task;
          return task;
        });

        await tester.tap(find.text('Save'));

        expect(verify(mockTasksCubit.updateTask(captureAny)).captured, [expectedTask]);
      });
    });

    group('weekly:', () {
      testWidgets('renders correctly', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();

        await tester.tap(recurrenceTypeButton);
        await tester.pumpAndSettle();

        await tester.tap(find.text('week'));
        await tester.pumpAndSettle();

        // Only the current weekday should be selected by default.
        final currentWeekday = today.weekday;

        final sundayChip = find.byWidgetPredicate((widget) =>
            widget is FilterChip &&
            widget.key == const Key('SU') &&
            widget.selected == (currentWeekday == DateTime.sunday));
        expect(sundayChip, findsOneWidget);

        final mondayChip = find.byWidgetPredicate((widget) =>
            widget is FilterChip &&
            widget.key == const Key('MO') &&
            widget.selected == (currentWeekday == DateTime.monday));
        expect(mondayChip, findsOneWidget);

        final tuesdayChip = find.byWidgetPredicate((widget) =>
            widget is FilterChip &&
            widget.key == const Key('TU') &&
            widget.selected == (currentWeekday == DateTime.tuesday));
        expect(tuesdayChip, findsOneWidget);

        final wednesdayChip = find.byWidgetPredicate((widget) =>
            widget is FilterChip &&
            widget.key == const Key('WE') &&
            widget.selected == (currentWeekday == DateTime.wednesday));
        expect(wednesdayChip, findsOneWidget);

        final thursdayChip = find.byWidgetPredicate((widget) =>
            widget is FilterChip &&
            widget.key == const Key('TH') &&
            widget.selected == (currentWeekday == DateTime.thursday));
        expect(thursdayChip, findsOneWidget);

        final fridayChip = find.byWidgetPredicate((widget) =>
            widget is FilterChip &&
            widget.key == const Key('FR') &&
            widget.selected == (currentWeekday == DateTime.friday));
        expect(fridayChip, findsOneWidget);

        final saturdayChip = find.byWidgetPredicate((widget) =>
            widget is FilterChip &&
            widget.key == const Key('SA') &&
            widget.selected == (currentWeekday == DateTime.saturday));
        expect(saturdayChip, findsOneWidget);
      });

      testWidgets('every week', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();

        await tester.tap(recurrenceTypeButton);
        await tester.pumpAndSettle();

        await tester.tap(find.text('week'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final expectedTask = initialTask.copyWith(
          dueDate: tomorrow,
          recurrenceRule: RecurrenceRule(
            frequency: Frequency.weekly,
            interval: 1,
            byWeekDays: {ByWeekDayEntry(today.weekday)},
          ),
        );

        when(mockTasksCubit.updateTask(any)).thenAnswer((invokation) async {
          final task = invokation.positionalArguments[0] as Task;
          return task;
        });

        expect(verify(mockTasksCubit.updateTask(captureAny)).captured, [expectedTask]);
      });

      testWidgets('every 2 weeks', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();

        await tester.tap(recurrenceTypeButton);
        await tester.pumpAndSettle();

        await tester.tap(find.text('week'));
        await tester.pumpAndSettle();

        await tester.enterText(find.text('1'), '2');
        await tester.tap(find.text('Save'));

        final expectedTask = initialTask.copyWith(
          dueDate: tomorrow,
          recurrenceRule: RecurrenceRule(
            frequency: Frequency.weekly,
            interval: 2,
            byWeekDays: {ByWeekDayEntry(today.weekday)},
          ),
        );

        when(mockTasksCubit.updateTask(any)).thenAnswer((invokation) async {
          final task = invokation.positionalArguments[0] as Task;
          return task;
        });

        expect(verify(mockTasksCubit.updateTask(captureAny)).captured, [expectedTask]);
      });

      testWidgets('every monday and wednesday', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();

        await tester.tap(recurrenceTypeButton);
        await tester.pumpAndSettle();

        await tester.tap(find.text('week'));
        await tester.pumpAndSettle();

        // Deselect the current weekday, to ensure none are selected at the start of the
        // test.
        final selectedWeekdayChip = find.byWidgetPredicate(
          (widget) => widget is FilterChip && widget.selected,
        );
        expect(selectedWeekdayChip, findsOneWidget);
        await tester.tap(selectedWeekdayChip);
        await tester.pumpAndSettle();

        final selectedChips = find.byWidgetPredicate(
          (widget) => widget is FilterChip && widget.selected,
        );
        expect(selectedChips, findsNothing);

        final mondayChip = find.byWidgetPredicate(
            (widget) => widget is FilterChip && widget.key == const Key('MO'));
        await tester.tap(mondayChip);
        await tester.pumpAndSettle();

        final wednesdayChip = find.byWidgetPredicate(
            (widget) => widget is FilterChip && widget.key == const Key('WE'));
        await tester.tap(wednesdayChip);
        await tester.pumpAndSettle();

        expect(selectedChips, findsNWidgets(2));

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final expectedRecurrenceRule = RecurrenceRule(
          frequency: Frequency.weekly,
          interval: 1,
          byWeekDays: {
            ByWeekDayEntry(DateTime.monday),
            ByWeekDayEntry(DateTime.wednesday),
          },
        );

        final updatedDueDate = expectedRecurrenceRule.nextInstance(today);

        final expectedTask = initialTask.copyWith(
          dueDate: updatedDueDate,
          recurrenceRule: expectedRecurrenceRule,
        );

        when(mockTasksCubit.updateTask(any)).thenAnswer((invokation) async {
          final task = invokation.positionalArguments[0] as Task;
          return task;
        });

        expect(verify(mockTasksCubit.updateTask(captureAny)).captured, [expectedTask]);
      });
    });

    group('monthly:', () {
      testWidgets('renders correctly', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();

        await tester.tap(recurrenceTypeButton);
        await tester.pumpAndSettle();

        await tester.tap(find.text('month'));
        await tester.pumpAndSettle();

        final int currentNumericDay = today.day;
        final String currentWeekday = numericToWeekdays[today.weekday]!;

        expect(find.text('Day $currentNumericDay'), findsOneWidget);
        expect(find.text('First'), findsOneWidget);
        expect(find.text(currentWeekday), findsOneWidget);
      });

      testWidgets('every month on the current day', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();

        await tester.tap(recurrenceTypeButton);
        await tester.pumpAndSettle();

        await tester.tap(find.text('month'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final expectedTask = initialTask.copyWith(
          dueDate: tomorrow,
          recurrenceRule: RecurrenceRule(
            frequency: Frequency.monthly,
            interval: 1,
            byMonthDays: {today.day},
          ),
        );

        when(mockTasksCubit.updateTask(any)).thenAnswer((invokation) async {
          final task = invokation.positionalArguments[0] as Task;
          return task;
        });

        expect(verify(mockTasksCubit.updateTask(captureAny)).captured, [expectedTask]);
      });

      testWidgets('every 2 months on the current day', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();

        await tester.tap(recurrenceTypeButton);
        await tester.pumpAndSettle();

        await tester.tap(find.text('month'));
        await tester.pumpAndSettle();

        await tester.enterText(find.text('1'), '2');
        await tester.tap(find.text('Save'));

        final expectedTask = initialTask.copyWith(
          dueDate: tomorrow,
          recurrenceRule: RecurrenceRule(
            frequency: Frequency.monthly,
            interval: 2,
            byMonthDays: {today.day},
          ),
        );

        when(mockTasksCubit.updateTask(any)).thenAnswer((invokation) async {
          final task = invokation.positionalArguments[0] as Task;
          return task;
        });

        expect(verify(mockTasksCubit.updateTask(captureAny)).captured, [expectedTask]);
      });

      testWidgets('every month on <day>', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();
        await tester.tap(recurrenceTypeButton);
        await tester.pumpAndSettle();
        await tester.tap(find.text('month'));
        await tester.pumpAndSettle();

        /// The default is the current day, so we need to change it to something else.
        final int currentNumericDay = today.day;
        final int targetNumericDay = (currentNumericDay == 5) ? 1 : 5;

        await tester.tap(find.text('Day $currentNumericDay'));
        await tester.pumpAndSettle();

        /// Scroll the DropdownMenu up to ensure the target day is visible.
        await tester.dragUntilVisible(
          find.text('Day 1'),
          find.byType(Scrollable).last,
          const Offset(0, 100),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Day $targetNumericDay'));
        await tester.pumpAndSettle();

        expect(find.text('Day $targetNumericDay'), findsOneWidget);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final expectedRecurrenceRule = RecurrenceRule(
          frequency: Frequency.monthly,
          interval: 1,
          byMonthDays: {targetNumericDay},
        );

        final updatedDueDate = expectedRecurrenceRule.nextInstance(today);

        final expectedTask = initialTask.copyWith(
          dueDate: updatedDueDate,
          recurrenceRule: expectedRecurrenceRule,
        );

        when(mockTasksCubit.updateTask(any)).thenAnswer((invokation) async {
          final task = invokation.positionalArguments[0] as Task;
          return task;
        });

        expect(verify(mockTasksCubit.updateTask(captureAny)).captured, [expectedTask]);
      });

      testWidgets('first Monday of every month', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();
        await tester.tap(recurrenceTypeButton);
        await tester.pumpAndSettle();
        await tester.tap(find.text('month'));
        await tester.pumpAndSettle();

        final Finder weekdayRadio = find.byWidgetPredicate(
          (widget) => widget is Radio && widget.value == DayOfMonthType.weekday,
        );
        await tester.tap(weekdayRadio);
        await tester.pumpAndSettle();

        expect(find.text('First'), findsOneWidget);

        final Finder weekdayDropdown = find
            .byWidgetPredicate(
              (widget) =>
                  widget is DropdownButtonFormField<int> &&
                  widget.initialValue == today.weekday,
            )
            .first;
        await tester.tap(weekdayDropdown);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Monday'));
        await tester.pumpAndSettle();

        expect(find.text('Monday'), findsOneWidget);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final expectedRecurrenceRule = RecurrenceRule(
          frequency: Frequency.monthly,
          interval: 1,
          byWeekDays: {ByWeekDayEntry(DateTime.monday, 1)},
        );

        final updatedDueDate = expectedRecurrenceRule.nextInstance(today);

        final expectedTask = initialTask.copyWith(
          dueDate: updatedDueDate,
          recurrenceRule: expectedRecurrenceRule,
        );

        when(mockTasksCubit.updateTask(any)).thenAnswer((invokation) async {
          final task = invokation.positionalArguments[0] as Task;
          return task;
        });

        expect(verify(mockTasksCubit.updateTask(captureAny)).captured, [expectedTask]);
      });
    });

    group('yearly:', () {
      testWidgets('every year on the current day', (WidgetTester tester) async {
        await tester.pumpWidget(_buildRecurrenceWidget());

        await tester.tap(find.text('Repeat'));
        await tester.pumpAndSettle();
        await tester.tap(recurrenceTypeButton);
        await tester.pumpAndSettle();
        await tester.tap(find.text('year'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final expectedRecurrenceRule = RecurrenceRule(
          frequency: Frequency.yearly,
          interval: 1,
          byMonthDays: {today.day},
          byMonths: {today.month},
        );

        final updatedDueDate = expectedRecurrenceRule.nextInstance(today);

        final expectedTask = initialTask.copyWith(
          dueDate: updatedDueDate,
          recurrenceRule: expectedRecurrenceRule,
        );

        when(mockTasksCubit.updateTask(any)).thenAnswer((invokation) async {
          final task = invokation.positionalArguments[0] as Task;
          return task;
        });

        expect(verify(mockTasksCubit.updateTask(captureAny)).captured, [expectedTask]);
      });
    });
  });
}

/// Reuseable function to build the widget under test to reduce boilerplate.
BlocProvider<TasksCubit> _buildRecurrenceWidget() {
  return BlocProvider<TasksCubit>.value(
    value: mockTasksCubit,
    child: const MaterialApp(
      home: Material(
        child: RecurrenceWidget(),
      ),
    ),
  );
}

extension on int {
  String toMonthString() {
    switch (this) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      default:
        return 'December';
    }
  }
}
