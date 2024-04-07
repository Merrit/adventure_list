import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rrule/rrule.dart';

import '../../enums/enums.dart';
import '../../tasks.dart';

final Set<ByWeekDayEntry> _daysOfWeek = {
  ByWeekDayEntry(DateTime.sunday),
  ByWeekDayEntry(DateTime.monday),
  ByWeekDayEntry(DateTime.tuesday),
  ByWeekDayEntry(DateTime.wednesday),
  ByWeekDayEntry(DateTime.thursday),
  ByWeekDayEntry(DateTime.friday),
  ByWeekDayEntry(DateTime.saturday),
};

final Set<int> weekdays = {
  DateTime.sunday,
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
};

extension _WeekdayHelper on int {
  /// Returns the weekday as a string.
  ///
  /// The string will be formatted like "Monday".
  String toWeekdayLabel() {
    switch (this) {
      case DateTime.sunday:
        return 'Sunday';
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      default:
        return 'Monday';
    }
  }
}

/// Cubit that manages the state of the task for the [RecurrenceWidget].
class _RecurrenceCubit extends Cubit<Task> {
  _RecurrenceCubit(Task task) : super(task);

  void updateTask(Task task) {
    // Due date should always be UTC, except when being displayed to the user.
    assert(task.dueDate!.isUtc);

    if (task.dueDate!.isBefore(DateTime.now().toUtc())) {
      final updatedDueDate = task.recurrenceRule!.nextInstance(task.dueDate!);
      task = task.copyWith(dueDate: updatedDueDate);
    }

    emit(task);
  }
}

/// Displays the recurrence of the task and allows the user to change it.
class RecurrenceWidget extends StatelessWidget {
  const RecurrenceWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final task = state.activeTask;
        if (task == null) return const SizedBox.shrink();

        final Widget? subtitle = (task.recurrenceRule != null) //
            ? Text(rRuleTextWithoutTime(task))
            : null;

        final recurrenceCubit = _RecurrenceCubit(task.copyWith());

        return ListTile(
          leading: const Icon(Icons.repeat),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return BlocProvider.value(
                  value: recurrenceCubit,
                  child: const _RecurrenceDialog(),
                );
              },
            );
          },
          title: const Text('Repeat'),
          subtitle: subtitle,
        );
      },
    );
  }

  /// The `toText` method returns a string like:
  /// "Daily, until Saturday, September 16, 2023 3:20:57 PM"
  ///
  /// We don't want the part with the time, so we remove it.
  String rRuleTextWithoutTime(Task task) {
    final timeRegex = RegExp(r'\b\d{1,2}:.*');

    String rRuleReadableText = task.recurrenceRule!.toText(
      l10n: RecurrenceRuleService.recurrenceRuleL10n,
    );

    rRuleReadableText = rRuleReadableText.replaceAll(timeRegex, '');
    return rRuleReadableText;
  }
}

/// The dialog that allows the user to change the recurrence of the task.
class _RecurrenceDialog extends StatefulWidget {
  const _RecurrenceDialog();

  @override
  State<_RecurrenceDialog> createState() => _RecurrenceDialogState();
}

class _RecurrenceDialogState extends State<_RecurrenceDialog> {
  late _RecurrenceCubit recurrenceCubit;
  late TasksCubit tasksCubit;

  @override
  void initState() {
    recurrenceCubit = context.read<_RecurrenceCubit>();
    final Task task = recurrenceCubit.state;

    // If the task doesn't have a due date, set it to today.
    final DateTime dueDate = task.dueDate ??
        DateTime.now()
            .copyWith(
              hour: 8,
              minute: 0,
              second: 0,
              millisecond: 0,
              microsecond: 0,
            )
            .toUtc();

    // If the task doesn't have a recurrence rule, set it to daily.
    final RecurrenceRule recurrenceRule = task.recurrenceRule ??
        RecurrenceRule(
          frequency: Frequency.daily,
          interval: 1,
        );

    recurrenceCubit.updateTask(
      task.copyWith(
        dueDate: dueDate,
        recurrenceRule: recurrenceRule,
      ),
    );

    tasksCubit = context.read<TasksCubit>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Repeats every'),
      content: SingleChildScrollView(
        /// Key needed for widget tests.
        key: const Key('singleChildScrollView'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const _RecurrenceIntervalWidget(),
                const SizedBox(width: 10),
                _RecurrenceTypeWidget(),
              ],
            ),
            const _DayOfWeekWidget(),
            const _DayOfMonthWidget(),
            const _RecurrenceTimeWidget(),
            const _StartsOnWidget(),
            const _EndDateWidget(),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            tasksCubit.updateTask(
              recurrenceCubit.state.copyWith(recurrenceRule: null),
            );
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.delete),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => saveChanges(context),
          child: const Text('Save'),
        ),
      ],
    );
  }

  /// Saves the changes to this task.
  void saveChanges(BuildContext context) {
    final Task task = context.read<_RecurrenceCubit>().state;
    tasksCubit.updateTask(task);
    Navigator.of(context).pop();
  }
}

/// Widget that displays the recurrence interval.
///
/// The recurrence interval is the number of days, weeks, months, or years
/// between each recurrence of the task.
class _RecurrenceIntervalWidget extends StatelessWidget {
  const _RecurrenceIntervalWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      child: BlocBuilder<_RecurrenceCubit, Task>(
        builder: (context, task) {
          return TextField(
            controller: TextEditingController(
              text: task.recurrenceRule!.interval.toString(),
            ),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
            onChanged: (value) {
              if (value == '') return;

              context.read<_RecurrenceCubit>().updateTask(
                    task.copyWith(
                      recurrenceRule: task.recurrenceRule!.copyWith(
                        interval: int.parse(value),
                      ),
                    ),
                  );
            },
          );
        },
      ),
    );
  }
}

/// Widget that displays the recurrence type (day, week, month, year).
class _RecurrenceTypeWidget extends StatelessWidget {
  _RecurrenceTypeWidget({Key? key}) : super(key: key);

  static final List<Frequency> frequencyOptions = [
    Frequency.daily,
    Frequency.weekly,
    Frequency.monthly,
    Frequency.yearly,
  ];

  final focusNode = FocusNode(debugLabel: 'RecurrenceTypeWidget');

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocBuilder<_RecurrenceCubit, Task>(
        builder: (context, task) {
          final int interval = task.recurrenceRule!.interval ?? 1;
          final bool repeatsMultiple = interval > 1;

          return DropdownButtonFormField<Frequency>(
            value: task.recurrenceRule?.frequency,
            focusNode: focusNode,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (value == null) return;

              Set<ByWeekDayEntry> byWeekDays = {};
              if (value == Frequency.weekly) {
                byWeekDays = {ByWeekDayEntry(DateTime.now().weekday)};
              }

              Set<int> byMonthDays = {};
              if (value == Frequency.monthly || value == Frequency.yearly) {
                byMonthDays = {DateTime.now().day};
              }

              Set<int> byMonths = {};
              if (value == Frequency.yearly) {
                byMonths = {DateTime.now().month};
              }

              final DateTime dueDate;
              if (value == Frequency.yearly) {
                // Set the due date to yesterday so that the next instance will be
                // calculated.
                dueDate = DateTimeHelper.today().subtract(const Duration(days: 1));
              } else {
                dueDate = task.dueDate!;
              }

              context.read<_RecurrenceCubit>().updateTask(
                    task.copyWith(
                      dueDate: dueDate,
                      recurrenceRule: task.recurrenceRule!.copyWith(
                        frequency: value,
                        byWeekDays: byWeekDays.toList(),
                        byMonthDays: byMonthDays.toList(),
                        byMonths: byMonths.toList(),
                      ),
                    ),
                  );

              // Remove focus from the dropdown button.
              FocusScope.of(context).requestFocus(FocusNode());
            },
            items: frequencyOptions.map((frequency) {
              return DropdownMenuItem<Frequency>(
                value: frequency,
                child: Text(frequency.toText(repeatsMultiple)),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// Widget that displays the days of the week the recurrence occurs on.
///
/// Only visible if the recurrence is weekly.
///
/// The user can select multiple days of the week, defaults to the current day.
class _DayOfWeekWidget extends StatelessWidget {
  const _DayOfWeekWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recurrenceCubit = context.read<_RecurrenceCubit>();

    return BlocBuilder<_RecurrenceCubit, Task>(
      builder: (context, task) {
        final RecurrenceRule? recurrenceRule = task.recurrenceRule;
        if (recurrenceRule == null) return const SizedBox.shrink();

        final bool isWeekly = recurrenceRule.frequency == Frequency.weekly;
        if (!isWeekly) return const SizedBox.shrink();

        final Set<ByWeekDayEntry> selectedDaysOfWeek = {...recurrenceRule.byWeekDays};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: _daysOfWeek.map((day) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FilterChip.elevated(
                    /// Key needed for widget tests.
                    key: Key(day.toString()),
                    label: Text(day.toString()[0]),
                    selected: selectedDaysOfWeek.contains(day),
                    showCheckmark: false,
                    onSelected: (selected) {
                      // Set the due date to yesterday so that the next instance will be
                      // calculated.
                      final DateTime dueDate = DateTimeHelper.today().subtract(
                        const Duration(days: 1),
                      );

                      if (selected) {
                        recurrenceCubit.updateTask(
                          task.copyWith(
                            dueDate: dueDate,
                            recurrenceRule: recurrenceRule.copyWith(
                              byWeekDays: selectedDaysOfWeek.toList()..add(day),
                            ),
                          ),
                        );
                      } else {
                        recurrenceCubit.updateTask(
                          task.copyWith(
                            dueDate: dueDate,
                            recurrenceRule: recurrenceRule.copyWith(
                              byWeekDays: selectedDaysOfWeek.toList()..remove(day),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

/// Widget that displays the day of the month the recurrence occurs on.
///
/// Only visible if the recurrence is monthly.
///
/// The user can select from Day 1 to Day 31, or "Last day".
class _DayOfMonthWidget extends StatefulWidget {
  const _DayOfMonthWidget({Key? key}) : super(key: key);

  @override
  State<_DayOfMonthWidget> createState() => _DayOfMonthWidgetState();
}

/// If the recurrence is [numeric], the user can select from Day 1 to Day 31, or
/// "Last day".
///
/// If the recurrence is [weekday], the user can select the first, second, third,
/// fourth, or last <weekday>.
enum DayOfMonthType { numeric, weekday }

class _DayOfMonthWidgetState extends State<_DayOfMonthWidget> {
  DayOfMonthType dayOfMonthType = DayOfMonthType.numeric;

  @override
  Widget build(BuildContext context) {
    final recurrenceCubit = context.read<_RecurrenceCubit>();

    return BlocBuilder<_RecurrenceCubit, Task>(
      builder: (context, task) {
        final RecurrenceRule? recurrenceRule = task.recurrenceRule;
        if (recurrenceRule == null) return const SizedBox.shrink();

        final bool isMonthly = recurrenceRule.frequency == Frequency.monthly;
        if (!isMonthly) return const SizedBox.shrink();

        /// The recurrence should be either numeric or weekday, but not both.
        if (recurrenceRule.hasByWeekDays) {
          assert(recurrenceRule.hasByMonthDays == false);
        }

        if (recurrenceRule.hasByMonthDays) {
          assert(recurrenceRule.hasByWeekDays == false);
        }

        /// The numeric day of the month, eg the 1st, 5th, 25th, etc.
        final int selectedDayOfMonth;
        if (recurrenceRule.hasByMonthDays) {
          selectedDayOfMonth = recurrenceRule.byMonthDays.first;
        } else {
          selectedDayOfMonth = DateTime.now().day;
        }

        /// The weekday, eg Monday, Tuesday, etc.
        final int selectedWeekday;
        if (recurrenceRule.hasByWeekDays) {
          selectedWeekday = recurrenceRule.byWeekDays.first.day;
        } else {
          selectedWeekday = DateTime.now().weekday;
        }

        /// The occurrence of the weekday, eg the first, second, third, fourth, or last.
        final int selectedWeekdayOccurrence;
        if (recurrenceRule.hasByWeekDays) {
          selectedWeekdayOccurrence = recurrenceRule.byWeekDays.first.occurrence ?? 1;
        } else {
          selectedWeekdayOccurrence = 1;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            RadioListTile(
              value: DayOfMonthType.numeric,
              groupValue: dayOfMonthType,
              contentPadding: const EdgeInsets.all(0),
              onChanged: (value) {
                if (value == null) return;

                setState(() => dayOfMonthType = value);

                recurrenceCubit.updateTask(
                  task.copyWith(
                    // Set the due date to yesterday so that the next instance will be
                    // calculated.
                    dueDate: DateTimeHelper.today().subtract(const Duration(days: 1)),
                    recurrenceRule: recurrenceRule.copyWith(
                      frequency: Frequency.monthly,
                      byWeekDays: [],
                    ),
                  ),
                );
              },
              title: DropdownButtonFormField<int>(
                value: selectedDayOfMonth,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value == null) return;

                  recurrenceCubit.updateTask(
                    task.copyWith(
                      // Set the due date to yesterday so that the next instance will be
                      // calculated.
                      dueDate: DateTimeHelper.today().subtract(const Duration(days: 1)),
                      recurrenceRule: recurrenceRule.copyWith(
                        frequency: Frequency.monthly,
                        byMonthDays: {value}.toList(),
                        byWeekDays: [],
                      ),
                    ),
                  );
                },
                items: [
                  for (int i = 1; i <= 31; i++)
                    DropdownMenuItem<int>(
                      value: i,
                      child: Text('Day ${i.toString()}'),
                    ),
                  const DropdownMenuItem<int>(
                    value: -1,
                    child: Text('Last day'),
                  ),
                ],
              ),
            ),
            RadioListTile(
              value: DayOfMonthType.weekday,
              groupValue: dayOfMonthType,
              contentPadding: const EdgeInsets.all(0),
              onChanged: (value) {
                if (value == null) return;

                setState(() => dayOfMonthType = value);

                recurrenceCubit.updateTask(
                  task.copyWith(
                    // Set the due date to yesterday so that the next instance will be
                    // calculated.
                    dueDate: DateTimeHelper.today().subtract(const Duration(days: 1)),
                    recurrenceRule: recurrenceRule.copyWith(
                      frequency: Frequency.monthly,
                      byMonthDays: [],
                      byWeekDays: {
                        ByWeekDayEntry(selectedWeekday, selectedWeekdayOccurrence)
                      }.toList(),
                    ),
                  ),
                );
              },
              title: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedWeekdayOccurrence,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value == null) return;

                        recurrenceCubit.updateTask(
                          task.copyWith(
                            // Set the due date to yesterday so that the next instance
                            // will be calculated.
                            dueDate:
                                DateTimeHelper.today().subtract(const Duration(days: 1)),
                            recurrenceRule: recurrenceRule.copyWith(
                              frequency: Frequency.monthly,
                              byMonthDays: [],
                              byWeekDays:
                                  {ByWeekDayEntry(selectedWeekday, value)}.toList(),
                            ),
                          ),
                        );
                      },
                      items: [
                        for (int i = 1; i <= 4; i++)
                          DropdownMenuItem<int>(
                            value: i,
                            child: Text(_monthlyOccurrenceToText(i)),
                          ),
                        const DropdownMenuItem<int>(
                          value: -1,
                          child: Text('Last'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: const Key('weekdayDropdown'),
                      value: selectedWeekday,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value == null) return;

                        recurrenceCubit.updateTask(
                          task.copyWith(
                            dueDate: DateTimeHelper.today(),
                            recurrenceRule: recurrenceRule.copyWith(
                              frequency: Frequency.monthly,
                              byMonthDays: [],
                              byWeekDays: {
                                ByWeekDayEntry(value, selectedWeekdayOccurrence)
                              }.toList(),
                            ),
                          ),
                        );
                      },
                      items: weekdays.map((weekday) {
                        return DropdownMenuItem<int>(
                          value: weekday,
                          child: Text(weekday.toWeekdayLabel()),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Returns the text for the monthly occurrence dropdown menu.
  String _monthlyOccurrenceToText(int occurrence) {
    switch (occurrence) {
      case 1:
        return 'First';
      case 2:
        return 'Second';
      case 3:
        return 'Third';
      case 4:
        return 'Fourth';
      default:
        return 'First';
    }
  }
}

/// Widget that displays the time the recurrence occurs at.
class _RecurrenceTimeWidget extends StatelessWidget {
  const _RecurrenceTimeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recurrenceCubit = context.read<_RecurrenceCubit>();

    return BlocBuilder<_RecurrenceCubit, Task>(
      builder: (context, task) {
        final RecurrenceRule? recurrenceRule = task.recurrenceRule;
        if (recurrenceRule == null) return const SizedBox.shrink();

        final DateTime dueDate = task.dueDate!.toLocal();
        final String timeText = dueDate.toTimeLabel();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            ActionChip.elevated(
              label: Text(timeText),
              onPressed: () async {
                final TimeOfDay? newTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(dueDate),
                );

                if (newTime == null) return;

                final DateTime newDueDate = dueDate.copyWith(
                  hour: newTime.hour,
                  minute: newTime.minute,
                );

                recurrenceCubit.updateTask(
                  task.copyWith(
                    dueDate: newDueDate.toUtc(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Widget that displays the date the recurrence starts on.
class _StartsOnWidget extends StatelessWidget {
  const _StartsOnWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recurrenceCubit = context.read<_RecurrenceCubit>();

    return BlocBuilder<_RecurrenceCubit, Task>(
      builder: (context, task) {
        final DateTime dueDate = task.dueDate!.toLocal();

        final RecurrenceRule? recurrenceRule = task.recurrenceRule;
        if (recurrenceRule == null) return const SizedBox.shrink();

        final String dueDateText = dueDate.toRecurrenceLabel();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Starts',
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
              ),
            ),
            const SizedBox(height: 8),
            ActionChip.elevated(
              label: Text(dueDateText),
              onPressed: () async {
                final DateTime? newDueDate = await showDatePicker(
                  context: context,
                  initialDate: dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );

                if (newDueDate == null) return;

                recurrenceCubit.updateTask(
                  task.copyWith(
                    dueDate: dueDate
                        .copyWith(
                          year: newDueDate.year,
                          month: newDueDate.month,
                          day: newDueDate.day,
                        )
                        .toUtc(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Widget that displays the date the recurrence ends on.
///
/// Includes 3 options: never, on a date, or after a number of recurrences.
///
/// If the recurrence is set to end on a date, the date picker will default to
/// 1 month after the start date (one year and one month if yearly).
///
/// If the recurrence is set to end after a number of recurrences, the number
/// will default to 30 for days, 13 for weeks, 12 for months, and 5 for years.
class _EndDateWidget extends StatelessWidget {
  const _EndDateWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recurrenceCubit = context.read<_RecurrenceCubit>();

    return BlocBuilder<_RecurrenceCubit, Task>(
      builder: (context, task) {
        final RecurrenceRule? recurrenceRule = task.recurrenceRule;
        if (recurrenceRule == null) return const SizedBox.shrink();

        final DateTime dueDate = task.dueDate!.toLocal();

        final DateTime endDate;
        if (recurrenceRule.until != null) {
          endDate = recurrenceRule.until!;
        } else {
          switch (recurrenceRule.frequency) {
            case Frequency.daily:
              endDate = dueDate.add(const Duration(days: 30));
            case Frequency.weekly:
              endDate = dueDate.add(const Duration(days: 13 * 7));
            case Frequency.monthly:
              endDate = dueDate.add(const Duration(days: 12 * 30));
            case Frequency.yearly:
              endDate = dueDate.add(const Duration(days: 5 * 365));
            default:
              endDate = dueDate;
          }
        }

        final String endDateText = endDate.toRecurrenceLabel();

        final endsAfterText = recurrenceRule.count?.toString() ?? '';

        final TextEditingController endsAfterTextController = TextEditingController(
          text: endsAfterText,
        )..selection = TextSelection.fromPosition(
            TextPosition(offset: endsAfterText.length),
          );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Ends',
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
              ),
            ),
            const SizedBox(height: 8),
            RadioListTile<RecurrenceEndType>(
              title: const Text('Never'),
              contentPadding: const EdgeInsets.all(0),
              value: RecurrenceEndType.never,
              groupValue: recurrenceRule.endType,
              onChanged: (value) {
                if (value == null) return;

                recurrenceCubit.updateTask(
                  task.copyWith(
                    recurrenceRule: recurrenceRule.copyWith(
                      clearUntil: true,
                      clearCount: true,
                    ),
                  ),
                );
              },
            ),
            RadioListTile<RecurrenceEndType>(
              title: Row(
                children: [
                  const SizedBox(
                    width: 50,
                    child: Text('On'),
                  ),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        key: const Key('recurrenceEndsOnDateButton'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final DateTime? newUntil = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );

                          if (newUntil == null) return;

                          recurrenceCubit.updateTask(
                            task.copyWith(
                              recurrenceRule: recurrenceRule.copyWith(
                                until: dueDate
                                    .copyWith(
                                      year: newUntil.year,
                                      month: newUntil.month,
                                      day: newUntil.day,
                                    )
                                    .toUtc(),
                                count: null,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Visibility(
                            visible: recurrenceRule.endType == RecurrenceEndType.onDate,
                            maintainAnimation: true,
                            maintainSize: true,
                            maintainState: true,
                            child: Text(endDateText),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.all(0),
              value: RecurrenceEndType.onDate,
              groupValue: recurrenceRule.endType,
              onChanged: (RecurrenceEndType? value) async {
                if (value == null) return;

                recurrenceCubit.updateTask(
                  task.copyWith(
                    recurrenceRule: recurrenceRule.copyWith(
                      until: endDate.toUtc(),
                      clearCount: true,
                    ),
                  ),
                );
              },
            ),
            RadioListTile<RecurrenceEndType>(
              title: Row(
                children: [
                  const SizedBox(
                    width: 50,
                    child: Text('After'),
                  ),
                  Expanded(
                    child: TextField(
                      key: const Key('recurrenceEndsAfterTextField'),
                      controller: endsAfterTextController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixText: 'times',
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value == '') return;

                        recurrenceCubit.updateTask(
                          task.copyWith(
                            recurrenceRule: recurrenceRule.copyWith(
                              count: int.parse(value),
                              clearUntil: true,
                            ),
                          ),
                        );
                      },
                      onTap: () => setEndsAfter(context),
                    ),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.all(0),
              value: RecurrenceEndType.afterOccurrences,
              groupValue: recurrenceRule.endType,
              onChanged: (RecurrenceEndType? value) async {
                if (value == null) return;

                setEndsAfter(context);
              },
            ),
          ],
        );
      },
    );
  }

  /// Sets the recurrence to end after a number of recurrences.
  void setEndsAfter(BuildContext context) {
    final recurrenceCubit = context.read<_RecurrenceCubit>();
    final Task task = recurrenceCubit.state;
    final RecurrenceRule recurrenceRule = task.recurrenceRule!;

    final int recurrences;
    switch (recurrenceRule.frequency) {
      case Frequency.daily:
        recurrences = 30;
      case Frequency.weekly:
        recurrences = 13;
      case Frequency.monthly:
        recurrences = 12;
      case Frequency.yearly:
        recurrences = 5;
      default:
        recurrences = 30;
    }

    recurrenceCubit.updateTask(
      task.copyWith(
        recurrenceRule: recurrenceRule.copyWith(
          count: recurrences,
          clearUntil: true,
        ),
      ),
    );
  }
}
