import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';

import '../tasks.dart';

class TasksPage extends StatelessWidget {
  static const routeName = '/';

  const TasksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return SafeArea(
      child: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final Widget largeBody = Row(
            children: const [
              CustomNavigationRail(),
              Flexible(child: TasksView()),
              TaskDetails(),
            ],
          );

          const Widget mobileBody = TasksView();

          return Scaffold(
            appBar: mediaQuery.isHandset ? const _TaskListAppBar() : null,
            drawer: mediaQuery.isHandset ? const CustomDrawer() : null,
            body: mediaQuery.isHandset ? mobileBody : largeBody,
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
