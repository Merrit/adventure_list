import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../../app/app.dart';
import '../../core/constants.dart';
import '../../core/helpers/helpers.dart';
import '../../notifications/notifications.dart';
import '../../settings/settings.dart';
import '../../window/window.dart';
import '../tasks.dart';

class TasksPage extends StatefulWidget {
  static const routeName = '/';

  const TasksPage({Key? key}) : super(key: key);

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  Widget body = const SizedBox();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return SafeArea(
      child: BlocBuilder<AppCubit, AppState>(
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
                Navigator.pushNamed(context, TaskDetails.routeName);
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
                transparentBackgroundEnabled =
                    context.select<SettingsCubit, bool>(
                  (cubit) =>
                      cubit.state.desktopWidgetSettings.transparentBackground,
                );
              } else {
                transparentBackgroundEnabled = false;
              }

              final Color backgroundColor =
                  (pinned && transparentBackgroundEnabled)
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
                body: AdaptiveLayout(
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
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showReleaseNotesDialog(
    BuildContext context,
    ReleaseNotes releaseNotes,
  ) {
    final appCubit = context.read<AppCubit>();

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

  const _TaskListAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: !MediaQuery.of(context).isSmallScreen,
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
            child: const Text('Show test notification'),
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
