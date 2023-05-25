import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/helpers/helpers.dart';
import '../../tasks.dart';

class TaskDetails extends StatelessWidget {
  static const routeName = '/task_details';

  const TaskDetails({Key? key}) : super(key: key);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(DiagnosticsProperty('task', tasksCubit.state.activeTask));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // If the screen is large enough, for example because the user resized the
    // window, we want to show the task details in the same page as the list of
    // tasks, so we return to the TasksPage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mediaQuery.isSmallScreen) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final Task? task = state.activeTask;

        final smallScreenView = WillPopScope(
          onWillPop: () async {
            tasksCubit.setActiveTask(null);
            Navigator.of(context).popUntil((route) => route.isFirst);
            return false;
          },
          child: Scaffold(
            appBar: AppBar(
              key: ValueKey(task),
              actions: const [
                _MoreActionsButton(),
              ],
            ),
            body: TaskDetailsView(key: ValueKey(task)),
          ),
        );

        final largeScreenView = TaskDetailsView(key: ValueKey(task));

        return (mediaQuery.isSmallScreen) ? smallScreenView : largeScreenView;
      },
    );
  }
}

class TaskDetailsView extends StatelessWidget {
  const TaskDetailsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final activeList = state.activeList;
        if (activeList == null) return const SizedBox();
        final Task? task = state.activeTask;
        if (task == null) return const SizedBox();

        final widgetContents = Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            padding: const EdgeInsets.all(12.0),
            controller: ScrollController(),
            children: [
              if (!mediaQuery.isSmallScreen)
                const Align(
                  alignment: Alignment.centerRight,
                  child: _MoreActionsButton(),
                ),
              const _TitleWidget(),
              const _DueDateWidget(),
              const _DueTimeWidget(),
              const _DescriptionWidget(),
              const _ParentSelectionWidget(),
              const SizedBox(height: 20),
              const Text('Sub-tasks'),
              ...activeList.items
                  .subtasksOf(task.id)
                  .map((e) => TaskTile(key: ValueKey(e), index: 0, task: e))
                  .toList(),
              _AddSubTaskWidget(parentTask: task),
            ],
          ),
        );

        return AnimatedSwitcher(
          key: ValueKey(task),
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) =>
              ScaleTransition(
            alignment: Alignment.centerLeft,
            scale: animation,
            child: child,
          ),
          child: widgetContents,
        );
      },
    );
  }
}

/// A button that shows a popup menu with more actions.
class _MoreActionsButton extends StatelessWidget {
  const _MoreActionsButton();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            onTap: () {
              final task = tasksCubit.state.activeTask;
              if (task == null) return;

              tasksCubit.clearCompletedTasks(parentId: task.id);
            },
            child: const Text('Clear completed sub-tasks'),
          ),
        ];
      },
    );
  }
}

class _TitleWidget extends StatelessWidget {
  const _TitleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final task = state.activeTask;
        if (task == null) return const SizedBox.shrink();

        TextStyle? textStyle;
        if (task.completed) {
          textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
                decoration: TextDecoration.lineThrough,
              );
        }

        return ListTile(
          leading: const Icon(Icons.title),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                final controller = TextEditingController(text: task.title);

                return AlertDialog(
                  title: const Text('Task name'),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    onSubmitted: (value) {
                      tasksCubit.updateTask(task.copyWith(title: value));
                      Navigator.of(context).pop();
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        tasksCubit.updateTask(
                          task.copyWith(title: controller.text),
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Save'),
                    ),
                  ],
                );
              },
            );
          },
          title: Text(
            task.title,
            style: textStyle,
          ),
          trailing: Checkbox(
            value: task.completed,
            onChanged: (value) {
              tasksCubit.updateTask(task.copyWith(completed: value ?? false));
            },
          ),
        );
      },
    );
  }
}

/// Due date widget.
///
/// Displays the due date of the task and allows the user to change it.
class _DueDateWidget extends StatefulWidget {
  const _DueDateWidget({Key? key}) : super(key: key);

  @override
  State<_DueDateWidget> createState() => _DueDateWidgetState();
}

class _DueDateWidgetState extends State<_DueDateWidget> {
  @override
  void initState() {
    super.initState();
    final Task? task = tasksCubit.state.activeTask;
    if (task == null) return;

    selectedDate = task.dueDate ?? noneDate;
  }

  final dateFocusNode = FocusNode();

  final noneDate = DateTime(1900);
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final Task? task = state.activeTask;
        if (task == null) return const SizedBox();

        final todayDate = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          8,
        );

        final tomorrowDate = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day + 1,
          8,
        );

        final bool selectedDateIsCustom = selectedDate != noneDate &&
            selectedDate != todayDate &&
            selectedDate != tomorrowDate;

        final List<DropdownMenuItem<DateTime>> dropdownItems = [
          DropdownMenuItem(
            value: noneDate,
            child: const Text('None'),
          ),
          DropdownMenuItem(
            value: todayDate,
            child: const Text('Today'),
          ),
          DropdownMenuItem(
            value: tomorrowDate,
            child: const Text('Tomorrow'),
          ),
          const DropdownMenuItem(
            value: null,
            child: Text('Pick a date'),
          ),
          if (selectedDateIsCustom)
            DropdownMenuItem(
              value: selectedDate,
              child: Text(
                DateFormat('EEEE, MMMM d').format(selectedDate!),
              ),
            ),
        ];

        final bool isOverdue = task.dueDate?.isBefore(DateTime.now()) ?? false;

        TextStyle? textStyle;
        if (isOverdue) {
          textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              );
        }

        return ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Due date'),
          trailing: IntrinsicWidth(
            child: DropdownButtonFormField<DateTime>(
              value: selectedDate,
              // Focus color is transparent so that the dropdown button doesn't
              // remain hightlighted after is has been closed.
              // Related issue: https://github.com/flutter/flutter/issues/94605
              focusColor: Colors.transparent,
              focusNode: dateFocusNode,
              onChanged: (DateTime? value) async {
                dateFocusNode.unfocus();

                DateTime? selectedDate;

                // Value is null when the selected dropdown item is Custom.
                if (value == null) {
                  selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                } else {
                  selectedDate = value;
                }

                if (value == noneDate) {
                  tasksCubit.updateTask(task.copyWith(dueDate: null));
                } else {
                  tasksCubit.updateTask(task.copyWith(dueDate: selectedDate));
                }
              },
              items: dropdownItems,
              style: textStyle,
            ),
          ),
        );
      },
    );
  }
}

/// Displays the due time of the task and allows the user to change it.
///
/// This widget is only visible if the task has a due date.
class _DueTimeWidget extends StatelessWidget {
  const _DueTimeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final task = state.activeTask;
        if (task == null || task.dueDate == null) {
          return const SizedBox.shrink();
        }

        final dueTime = TimeOfDay.fromDateTime(task.dueDate!);

        final trailing = Text(
          DateFormat('h:mm a').format(task.dueDate!),
        );

        return ListTile(
          leading: const Icon(Icons.access_time),
          onTap: () async {
            final TimeOfDay? timeOfDay = await showTimePicker(
              context: context,
              initialTime: dueTime,
            );

            if (timeOfDay == null) return;

            tasksCubit.updateTask(
              task.copyWith(
                dueDate: DateTime(
                  task.dueDate!.year,
                  task.dueDate!.month,
                  task.dueDate!.day,
                  timeOfDay.hour,
                  timeOfDay.minute,
                ),
              ),
            );
          },
          title: const Text('Due time'),
          trailing: trailing,
        );
      },
    );
  }
}

/// Displays the description of the task and allows the user to change it.
class _DescriptionWidget extends StatelessWidget {
  const _DescriptionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final task = state.activeTask;
        if (task == null) return const SizedBox.shrink();

        final Widget? subtitle = (task.description != null) //
            ? Text(task.description!)
            : null;

        return ListTile(
          leading: const Icon(Icons.description),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                final controller = TextEditingController(
                  text: task.description,
                );

                return AlertDialog(
                  title: const Text('Task description'),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    onSubmitted: (value) {
                      tasksCubit.updateTask(task.copyWith(description: value));
                      Navigator.of(context).pop();
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        tasksCubit.updateTask(
                          task.copyWith(description: controller.text),
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Save'),
                    ),
                  ],
                );
              },
            );
          },
          title: const Text('Description'),
          subtitle: subtitle,
        );
      },
    );
  }
}

/// Displays the parent task of the active task and allows the user to change
/// it.
class _ParentSelectionWidget extends StatelessWidget {
  const _ParentSelectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final task = state.activeTask;
        if (task == null) return const SizedBox.shrink();

        final activeList = state.activeList;
        if (activeList == null) return const SizedBox.shrink();

        final Task? parentTask = activeList //
            .items
            .getTaskById(task.parent ?? '');

        final Widget subtitle = Text(parentTask?.title ?? 'None');

        return ListTile(
          leading: const Icon(Icons.arrow_upward),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Parent task'),
                  content: BlocBuilder<TasksCubit, TasksState>(
                    builder: (context, state) {
                      final List<Task> tasks = activeList.items
                          .topLevelTasks()
                          .where((t) => t.id != task.id)
                          .toList();

                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              onTap: () {
                                tasksCubit.updateTask(
                                  task.copyWith(parent: null),
                                );
                                Navigator.of(context).pop();
                              },
                              title: const Text('None'),
                            ),
                            ...tasks.map(
                              (t) => ListTile(
                                onTap: () {
                                  tasksCubit.updateTask(
                                    task.copyWith(parent: t.id),
                                  );
                                  Navigator.of(context).pop();
                                },
                                title: Text(t.title),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                );
              },
            );
          },
          title: const Text('Parent task'),
          subtitle: subtitle,
        );
      },
    );
  }
}

class _AddSubTaskWidget extends StatelessWidget {
  final Task parentTask;

  _AddSubTaskWidget({
    Key? key,
    required this.parentTask,
  }) : super(key: key);

  final addSubTaskFocusNode = FocusNode(debugLabel: 'AddSubTaskFocusNode');
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add),
      title: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Add sub-task',
          border: InputBorder.none,
        ),
        focusNode: addSubTaskFocusNode,
        onSubmitted: (value) {
          if (value.trim() == '') return;

          tasksCubit.createTask(
            Task(
              parent: parentTask.id,
              taskListId: parentTask.taskListId,
              title: value,
            ),
          );
        },
      ),
    );
  }
}
