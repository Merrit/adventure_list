import 'dart:developer';

import 'package:device_type/device_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layout/layout.dart';

import '../../../application/home/cubit/home_cubit.dart';
import '../../../domain/domain.dart';
import '../../home/home.dart';
import '../../styles.dart';
import '../todo.dart';

/// The app's primary view.
class TodoView extends StatelessWidget {
  const TodoView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state.activeList == null) Scaffold.of(context).openDrawer();
      },
      builder: (context, state) {
        if (state.loadingTodoLists) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final haveActiveList = (state.activeList != null);

        final double maxWidth = context.layout.value(
          xs: 0,
          sm: 120,
          md: 180,
          xl: 220,
        );

        final isXs = context.layout.breakpoint.isXs;

        log('maxWidth: $maxWidth', name: 'TodoView');

        final _isLargeFormFactor = Device.isLargeFormFactor(context);

        final List<Widget>? _todoTiles = state.activeList?.todos
            .where((element) => !element.isComplete)
            .map((todo) => TodoTile(
                  todo: todo,
                ))
            .toList();

        // On larger screens this row contains the Drawer.
        return Row(
          children: [
            if (_isLargeFormFactor) const CustomDrawer(),
            if (!isXs) const SizedBox(width: 50),
            Flexible(
              flex: isXs ? 1 : 3,
              child: haveActiveList
                  ? ListView(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      children: [
                        ...?_todoTiles,
                        const NewTodoButton(),
                        const _CompletedItems(),
                      ],
                    )
                  : const Center(
                      child: Text('Choose a list to load'),
                    ),
            ),
            if (!isXs) const Spacer(),
          ],
        );
      },
    );
  }
}

class _CompletedItems extends StatelessWidget {
  const _CompletedItems({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final List<Todo> completedItems = state.activeList!.todos
            .where(
              (element) => element.isComplete,
            )
            .toList();

        if (completedItems.isEmpty) return const SizedBox();

        final Widget _title = Text(
          'Completed items',
          style: TextStyle(
            color: CustomColors.fadedColor,
          ),
        );

        final List<Widget> _completedItemTiles = completedItems
            .map((todo) => Align(
                  alignment: Alignment.topLeft,
                  child: TodoTile(
                    todo: todo,
                  ),
                ))
            .toList();

        return ExpansionTile(
          title: _title,
          collapsedIconColor: CustomColors.fadedColor,
          children: [
            ..._completedItemTiles,
          ],
        );
      },
    );
  }
}
