import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';
import 'package:intl/intl.dart';

import '../../../core/helpers/helpers.dart';
import '../../tasks.dart';

class TaskDetails extends StatelessWidget {
  static const routeName = 'task_details';

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
            body: const TaskDetailsView(),
          ),
        );

        const largeScreenView = TaskDetailsView();

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
              const _DescriptionWidget(),
              const _ParentSelectionWidget(),
              const SizedBox(height: 20),
              const Text('Sub-tasks'),
              ...state.activeList!.items
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
          title: Text(task.title),
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
            ),
          ),
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

class _ParentSelectionWidget extends StatefulWidget {
  const _ParentSelectionWidget({Key? key}) : super(key: key);

  @override
  State<_ParentSelectionWidget> createState() => _ParentSelectionWidgetState();
}

class _ParentSelectionWidgetState extends State<_ParentSelectionWidget> {
  @override
  void initState() {
    super.initState();
    focusNode = FocusNode(debugLabel: 'parentSelectorFocusNode')
      ..addListener(() {
        // If the DropdownButton is deselected it should not be highlighted.
        if (focusNode.hasPrimaryFocus) focusNode.unfocus();
      });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  late final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final task = state.activeTask;
        if (task == null) return const SizedBox();

        final tasks = state.activeList?.items //
            .where(
                (e) => e.id != task.id && (e.parent == null || e.parent == ''))
            .toList();
        if (tasks == null) return const SizedBox();

        tasks.insert(
          0,
          Task(
            taskListId: '',
            title: 'None',
          ),
        );

        return ListTile(
          title: const Text('Parent task'),
          trailing: SizedBox(
            width: 200,
            child: DropdownButton<Task>(
              focusNode: focusNode,
              isExpanded: true,
              hint: const Text('None'),
              items: tasks
                  .map((e) => DropdownMenuItem<Task>(
                        value: e,
                        child: Text(
                          e.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              value: tasks
                  .firstWhereOrNull((element) => element.id == task.parent),
              onChanged: (Task? value) {
                if (value == null) return;
                if (value.title == 'None') {
                  tasksCubit.updateTask(task.copyWith(parent: ''));
                } else {
                  tasksCubit.updateTask(task.copyWith(parent: value.id));
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _AddSubTaskWidget extends StatelessWidget {
  final Task parentTask;

  const _AddSubTaskWidget({
    Key? key,
    required this.parentTask,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextInputListTile(
      placeholderText: 'Add sub-task',
      leading: const Icon(Icons.add),
      callback: (String value) {
        tasksCubit.createTask(
          Task(
            parent: parentTask.id,
            taskListId: parentTask.taskListId,
            title: value,
          ),
        );
      },
      retainFocus: true,
    );
  }
}
