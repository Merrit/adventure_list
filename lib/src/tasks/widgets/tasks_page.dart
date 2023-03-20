import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

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
    final width = mediaQuery.size.width;
    final bool isSmall = width < 600;

    return SafeArea(
      child: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final Widget bodyContainer = Row(
            children: [
              if (!isSmall) const VerticalDivider(),
              const Flexible(
                flex: 1,
                child: TasksView(),
              ),
            ],
          );

          return Scaffold(
            appBar: mediaQuery.isHandset ? const _TaskListAppBar() : null,
            drawer: (isSmall)
                ? const CustomNavigationRail(breakpoint: Breakpoints.small)
                : null,
            body: AdaptiveLayout(
              primaryNavigation: SlotLayout(
                config: <Breakpoint, SlotLayoutConfig>{
                  Breakpoints.mediumAndUp: SlotLayout.from(
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
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state.activeList == null) return AppBar();

        final TaskList activeList = state.activeList!;

        return AppBar(
          title: Text(activeList.title),
        );
      },
    );
  }
}
