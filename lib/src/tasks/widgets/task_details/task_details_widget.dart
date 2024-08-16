import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';
import 'package:rrule/rrule.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../core/helpers/helpers.dart';
import '../../tasks.dart';
import 'task_details.dart';

class TaskDetailsWidget extends StatefulWidget {
  static const routeName = '/task_details';

  const TaskDetailsWidget({Key? key}) : super(key: key);

  @override
  State<TaskDetailsWidget> createState() => _TaskDetailsWidgetState();
}

class _TaskDetailsWidgetState extends State<TaskDetailsWidget> {
  late TasksCubit tasksCubit;

  @override
  void initState() {
    super.initState();
    tasksCubit = context.read<TasksCubit>();
  }

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

        if (task == null) {
          // If there is no active task, we want to go back to the TasksPage.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          });
          // We return an empty widget so futher code doesn't have to deal with
          // nullability.
          return const SizedBox();
        }

        final smallScreenView = PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            tasksCubit.setActiveTask(null);
            SchedulerBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            });
          },
          child: Scaffold(
            appBar: AppBar(
              key: ValueKey(task),
              actions: const [
                ContextMenuButton(),
              ],
            ),
            body: TaskDetailsView(key: ValueKey(task)),
            persistentFooterButtons: [
              TextButton(
                onPressed: () => setTaskCompleted(
                  context: context,
                  tasksCubit: tasksCubit,
                  task: task,
                  completed: true,
                ),
                child: Text(LocaleKeys.markCompleted.tr()),
              )
            ],
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
                  child: ContextMenuButton(),
                ),
              const _TitleWidget(),
              const DueDateWidget(),
              const DueTimeWidget(),
              const RecurrenceWidget(),
              const DescriptionWidget(),
              const ParentSelectionWidget(),
              const SizedBox(height: 20),
              const SubTasksListWidget(),
              AddSubTaskWidget(parentTask: task),
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

/// A button that shows a popup menu with more actions for the task.
class ContextMenuButton extends StatelessWidget {
  const ContextMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final tasksCubit = context.read<TasksCubit>();

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final task = state.activeTask;
        if (task == null) return const SizedBox.shrink();

        final deleteCompletedSubtasksButton = MenuItemButton(
          leadingIcon: const Icon(Icons.clear_all),
          onPressed: () {
            tasksCubit.deleteCompletedTasks(parentId: task.id);
          },
          child: Text(
            LocaleKeys.deleteCompletedSubtasks.tr(),
          ),
        );

        /// List of TaskLists so that the user can move the task to another list. The
        /// current list has a checkmark next.
        final listChoiceButtons = state.taskLists.map(
          (list) {
            final bool isCurrentList = (list.id == task.taskListId);

            return MenuItemButton(
              leadingIcon: Icon(
                Icons.check,
                color: (isCurrentList) ? null : Colors.transparent,
              ),
              onPressed: () {
                if (isCurrentList) return;

                tasksCubit.moveTaskToList(task: task, newListId: list.id);
              },
              child: Text(list.title),
            );
          },
        );

        return MenuAnchor(
          builder: (context, controller, child) {
            return IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            );
          },
          menuChildren: [
            const _DeleteTaskButton(),
            deleteCompletedSubtasksButton,
            const PopupMenuDivider(),
            ...listChoiceButtons,
          ],
        );
      },
    );
  }
}

/// Button in the context menu to delete the task.
class _DeleteTaskButton extends StatelessWidget {
  const _DeleteTaskButton();

  @override
  Widget build(BuildContext context) {
    final tasksCubit = context.read<TasksCubit>();

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final task = state.activeTask;
        if (task == null) return const SizedBox.shrink();

        return MenuItemButton(
          leadingIcon: const Icon(Icons.delete),
          onPressed: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final command = DeleteTaskCommand(cubit: tasksCubit, task: task);

            await command.execute();

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(LocaleKeys.deleteTaskSuccessful.tr()),
                action: SnackBarAction(
                  label: LocaleKeys.undo.tr(),
                  onPressed: () async => await command.undo(),
                ),
              ),
            );
          },
          child: Text(
            LocaleKeys.delete.tr(),
          ),
        );
      },
    );
  }
}

class _TitleWidget extends StatelessWidget {
  const _TitleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tasksCubit = context.read<TasksCubit>();

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
        );
      },
    );
  }
}

/// Due date widget.
///
/// Displays the due date of the task and allows the user to change it.
class DueDateWidget extends StatelessWidget {
  const DueDateWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tasksCubit = context.read<TasksCubit>();

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final Task? task = state.activeTask;
        if (task == null) return const SizedBox();

        final String titleText;
        if (task.dueDate == null) {
          titleText = 'Date/time';
        } else {
          /// `toDueDateLabel` returns a string like "Wed., Aug. 4, 10:00 AM"
          /// and we want to remove the end with the time.
          titleText = task.dueDate!.toDueDateLabel().split(', ').where((s) {
            return !s.contains(':');
          }).join(', ');
        }

        final Widget title = Text(titleText);

        final Widget? trailing;
        if (task.dueDate == null) {
          trailing = null;
        } else {
          trailing = IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              tasksCubit.updateTask(task.copyWith(
                dueDate: null,
                recurrenceRule: null,
              ));
            },
          );
        }

        return ListTile(
          leading: const Icon(Icons.calendar_today),
          title: title,
          trailing: trailing,
          onTap: () async {
            DateTime? selectedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );

            if (selectedDate == null) return;

            // Time defaults to 8 AM
            selectedDate = selectedDate.copyWith(hour: 8, minute: 0);
            await tasksCubit.updateTask(task.copyWith(dueDate: selectedDate.toUtc()));
          },
        );
      },
    );
  }
}

/// Displays the due time of the task and allows the user to change it.
///
/// This widget is only visible if the task has a due date.
class DueTimeWidget extends StatelessWidget {
  const DueTimeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tasksCubit = context.read<TasksCubit>();

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final task = state.activeTask;
        if (task == null || task.dueDate == null) {
          return const SizedBox.shrink();
        }

        final dueDate = task.dueDate!.toLocal();

        final dueTime = TimeOfDay.fromDateTime(dueDate);

        final timeString = DateFormat('h:mm a') //
            .format(dueDate)
            .replaceAll('.', '')
            .toUpperCase();

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
                  dueDate.year,
                  dueDate.month,
                  dueDate.day,
                  timeOfDay.hour,
                  timeOfDay.minute,
                ).toUtc(),
              ),
            );
          },
          title: Text(timeString),
        );
      },
    );
  }
}

/// Displays the description of the task and allows the user to change it.
class DescriptionWidget extends StatelessWidget {
  const DescriptionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tasksCubit = context.read<TasksCubit>();

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
class ParentSelectionWidget extends StatelessWidget {
  const ParentSelectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tasksCubit = context.read<TasksCubit>();

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

class AddSubTaskWidget extends StatelessWidget {
  final Task parentTask;

  AddSubTaskWidget({
    Key? key,
    required this.parentTask,
  }) : super(key: key);

  final addSubTaskFocusNode = FocusNode(debugLabel: 'AddSubTaskFocusNode');
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final tasksCubit = context.read<TasksCubit>();

    return ListTile(
      leading: const Icon(Icons.add),
      title: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: LocaleKeys.subtasks_addSubtask.tr(),
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
