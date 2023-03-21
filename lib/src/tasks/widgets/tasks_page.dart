import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/helpers/helpers.dart';
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
      child: BlocBuilder<TasksCubit, TasksState>(
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
            ],
          );

          return Scaffold(
            appBar: (mediaQuery.isSmallScreen) ? const _TaskListAppBar() : null,
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
    );
  }
}
