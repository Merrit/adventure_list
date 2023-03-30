import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/helpers/helpers.dart';
import '../../notifications/notifications.dart';
import '../tasks.dart';

class TasksPage extends StatefulWidget {
  static const routeName = '/';

  const TasksPage({Key? key}) : super(key: key);

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  Widget body = const SizedBox();

  /// Checks if there is an active task and what the current screen size is.
  ///
  /// If there is an active task and we are on a small screen, we want to
  /// navigate to the task details page.
  void checkForActiveTask(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final state = context.read<TasksCubit>().state;
    if (state.activeTask != null && mediaQuery.isSmallScreen) {
      Navigator.of(context).pushNamed(TaskDetails.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForActiveTask(context);
    });

    final mediaQuery = MediaQuery.of(context);

    return SafeArea(
      child: BlocConsumer<TasksCubit, TasksState>(
        listener: (context, state) {
          // If there is an active task and we are on a small screen, we want to
          // navigate to the task details page.
          if (state.activeTask != null && mediaQuery.isSmallScreen) {
            Navigator.of(context).pushNamed(TaskDetails.routeName);
          }
        },
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final Widget bodyContainer = Row(
            children: [
              if (!mediaQuery.isSmallScreen) const VerticalDivider(),
              const Flexible(
                flex: 1,
                child: TasksView(),
              ),
              if (!mediaQuery.isSmallScreen) const VerticalDivider(),
            ],
          );

          final PreferredSizeWidget? appBar;
          if (mediaQuery.isSmallScreen) {
            appBar = const _TaskListAppBar();
          } else if (kDebugMode) {
            appBar = AppBar(
              title: const Text('Debug'),
              actions: const [_DebugMenuButton()],
            );
          } else {
            appBar = null;
          }

          return Scaffold(
            appBar: appBar,
            drawer: (mediaQuery.isSmallScreen)
                ? const CustomNavigationRail(breakpoint: Breakpoints.small)
                : null,
            body: AdaptiveLayout(
              primaryNavigation: SlotLayout(
                config: <Breakpoint, SlotLayoutConfig>{
                  Breakpoints.large: SlotLayout.from(
                    key: const Key('Primary Navigation Large'),
                    // inAnimation: AdaptiveScaffold.leftOutIn,
                    builder: (_) => const CustomNavigationRail(
                      breakpoint: Breakpoints.large,
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
              secondaryBody: SlotLayout(
                config: {
                  Breakpoints.large: SlotLayout.from(
                    key: const Key('Secondary Body Standard'),
                    builder: (_) => const TaskDetails(),
                  ),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TaskListAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final preferredSize = const Size.fromHeight(kToolbarHeight);

  const _TaskListAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const TasksHeader(),
      actions: const [_DebugMenuButton()],
    );
  }
}

/// A button that shows a popup menu with debug options.
class _DebugMenuButton extends StatelessWidget {
  const _DebugMenuButton();

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox();

    return PopupMenuButton(
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            child: const Text('Show notification'),
            onTap: () async {
              await Future.delayed(const Duration(seconds: 5));
              NotificationsCubit.instance.showNotification(
                title: 'Test notification',
                body: 'This is a test notification',
                payload: 'test payload',
              );
            },
          ),
        ];
      },
    );
  }
}
