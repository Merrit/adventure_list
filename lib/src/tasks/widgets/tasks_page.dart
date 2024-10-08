import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../../../generated/locale_keys.g.dart';
import '../../app/app.dart';
import '../../core/constants.dart';
import '../../core/widgets/input_dialog.dart';
import '../../settings/settings.dart';
import '../../window/window.dart';
import '../tasks.dart';

class TasksPage extends StatefulWidget {
  static const routeName = '/';

  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  Widget body = const SizedBox();

  final focusNode = FocusNode(
    debugLabel: 'Background node',
    skipTraversal: true,
  );

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (state.releaseNotes != null) {
            _showReleaseNotesDialog(context, state.releaseNotes!);
          }
        });

        return BlocConsumer<TasksCubit, TasksState>(
          listener: (context, state) {
            // If there is an active task and we are on a small screen, we want to
            // navigate to the task details page.
            if (state.activeTask != null && mediaQuery.isSmallScreen) {
              Navigator.pushNamed(context, TaskDetailsWidget.routeName);
            }

            // If there is an error message, show a dialog.
            if (state.errorMessage != null) {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(LocaleKeys.error_error.tr()),
                  content: Text(state.errorMessage!),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final bool pinned;
            if (defaultTargetPlatform.isDesktop) {
              pinned = context.select<WindowCubit, bool>(
                (cubit) => cubit.state.pinned,
              );
            } else {
              pinned = false;
            }

            final bool transparentBackgroundEnabled;
            if (defaultTargetPlatform.isDesktop) {
              transparentBackgroundEnabled = context.select<SettingsCubit, bool>(
                (cubit) => cubit.state.desktopWidgetSettings.transparentBackground,
              );
            } else {
              transparentBackgroundEnabled = false;
            }

            final Color backgroundColor = (pinned && transparentBackgroundEnabled)
                ? Colors.transparent
                : Theme.of(context).scaffoldBackgroundColor;

            final Widget bodyContainer = Row(
              children: [
                if (!mediaQuery.isSmallScreen) const VerticalDivider(),
                const Flexible(
                  flex: 1,
                  child: TasksView(),
                ),
              ],
            );

            return Scaffold(
              appBar: const _TaskListAppBar(),
              drawer: (mediaQuery.isSmallScreen)
                  ? const CustomNavigationRail(breakpoint: Breakpoints.small)
                  : null,
              backgroundColor: backgroundColor,
              body: SafeArea(
                /// GestureDetector & FocusNode allow clicking outside input
                /// areas in order to deselect them as expected on web &
                /// desktop platforms.
                ///
                /// In addition, if there is an active task and we are on a
                /// large screen, the task will be collapsed when clicking
                /// outside of it.
                child: GestureDetector(
                  onTap: () {
                    focusNode.requestFocus();
                    context.read<TasksCubit>().setActiveTask(null);
                  },
                  child: AdaptiveLayout(
                    primaryNavigation: SlotLayout(
                      config: <Breakpoint, SlotLayoutConfig>{
                        Breakpoints.mediumAndUp: SlotLayout.from(
                          key: const Key('Primary Navigation Large'),
                          builder: (_) => const CustomNavigationRail(
                            breakpoint: Breakpoints.mediumAndUp,
                          ),
                        ),
                      },
                    ),
                    body: SlotLayout(
                      config: {
                        Breakpoints.standard: SlotLayout.from(
                          key: const Key('Body Standard'),
                          builder: (_) => bodyContainer,
                        ),
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Whether or not the release notes dialog has been shown.
  ///
  /// This is used to prevent the dialog from showing multiple times,
  /// for example if the window is resized.
  bool shownReleaseNotesDialog = false;

  Future<void> _showReleaseNotesDialog(
    BuildContext context,
    ReleaseNotes releaseNotes,
  ) {
    if (shownReleaseNotesDialog) return Future.value();

    final appCubit = context.read<AppCubit>();
    shownReleaseNotesDialog = true;

    return showDialog(
      context: context,
      builder: (context) => ReleaseNotesDialog(
        releaseNotes: releaseNotes,
        donateCallback: () => appCubit.launchURL(kDonateUrl),
        launchURL: (url) => appCubit.launchURL(url),
        onClose: () {
          appCubit.dismissReleaseNotesDialog();
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _TaskListAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final preferredSize = const Size.fromHeight(kToolbarHeight);

  const _TaskListAppBar();

  @override
  Widget build(BuildContext context) {
    final Widget title = BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final TaskList? taskList = state.activeList;
        if (taskList == null) return const SizedBox();

        return Text(
          taskList.title,
          style: const TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );

    return AppBar(
      centerTitle: !MediaQuery.of(context).isSmallScreen,
      title: title,
      actions: const [_ListOptionsButton()],
    );
  }
}

/// A popup menu button that shows options for the current list.
class _ListOptionsButton extends StatefulWidget {
  const _ListOptionsButton();

  @override
  State<_ListOptionsButton> createState() => _ListOptionsButtonState();
}

class _ListOptionsButtonState extends State<_ListOptionsButton> {
  late final TasksCubit tasksCubit;

  @override
  void initState() {
    tasksCubit = context.read<TasksCubit>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      tooltip: LocaleKeys.listSettings_title.tr(),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: LocaleKeys.listSettings_renameList,
            child: Text(LocaleKeys.listSettings_renameList.tr()),
          ),
          PopupMenuItem(
            value: LocaleKeys.listSettings_deleteList,
            child: Text(LocaleKeys.listSettings_deleteList.tr()),
          ),
          PopupMenuItem(
            value: LocaleKeys.deleteCompleted,
            child: Text(LocaleKeys.deleteCompleted.tr()),
          ),
        ];
      },
      onSelected: (value) async {
        switch (value) {
          case LocaleKeys.listSettings_renameList:
            _showRenameListDialog(context);
          case LocaleKeys.listSettings_deleteList:
            _showDeleteListDialog(context);
          case LocaleKeys.deleteCompleted:
            final bool confirmed = await _confirmDeleteCompletedTasks();
            if (confirmed) {
              await _deleteCompletedTasks();
            }
        }
      },
    );
  }

  /// Shows a dialog to confirm deleting all completed tasks.
  Future<bool> _confirmDeleteCompletedTasks() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(LocaleKeys.deleteCompleted.tr()),
            content: Text(LocaleKeys.deleteCompletedConfirmation.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(LocaleKeys.cancel.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  LocaleKeys.delete.tr(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Deletes all completed tasks in the active task list.
  Future<void> _deleteCompletedTasks() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final command = DeleteCompletedTasksCommand(
      cubit: tasksCubit,
      taskList: tasksCubit.state.activeList!,
    );

    await command.execute();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(LocaleKeys.deleteCompletedSuccess.tr()),
        action: SnackBarAction(
          label: LocaleKeys.undo.tr(),
          onPressed: () => command.undo(),
        ),
      ),
    );
  }

  Future<void> _showRenameListDialog(BuildContext context) async {
    final tasksCubit = context.read<TasksCubit>();
    final taskList = tasksCubit.state.activeList!;

    final String? newName = await showInputDialog(
      context: context,
      title: LocaleKeys.listSettings_renameList.tr(),
      initialValue: taskList.title,
    );

    if (newName == null || newName.isEmpty) return;

    tasksCubit.updateList(
      taskList.copyWith(title: newName),
    );
  }

  Future<void> _showDeleteListDialog(BuildContext context) async {
    final tasksCubit = context.read<TasksCubit>();
    final taskList = tasksCubit.state.activeList!;

    final bool? delete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.listSettings_deleteListName.tr(
          args: [taskList.title],
        )),
        content: Text(LocaleKeys.listSettings_confirmDelete.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              LocaleKeys.delete.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (delete != true) return;

    await tasksCubit.deleteList();
  }
}
