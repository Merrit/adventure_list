import 'package:flutter/material.dart' hide PopupMenuButton, PopupMenuItem;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/core.dart';
import '../../core/helpers/helpers.dart';
import '../tasks.dart';

class TasksHeader extends StatelessWidget {
  const TasksHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final TaskList? taskList = state.activeList;
        if (taskList == null) return const SizedBox();

        /// SingleChildScrollView is used to prevent the header from
        /// overflowing when resizing the window.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                taskList.title,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: Opacity(
                  opacity: 0.5,
                  child: Transform.scale(
                    scale: 0.9,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            if (MediaQuery.of(context).isSmallScreen) {
                              Navigator.pushNamed(
                                context,
                                TaskListSettingsPage.routeName,
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  final mediaQuery = MediaQuery.of(context);

                                  return AlertDialog(
                                    title: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        SizedBox(),
                                        Text('List Settings'),
                                        CloseButton(),
                                      ],
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 20.0,
                                      horizontal: 100.0,
                                    ),
                                    content: SizedBox(
                                      width: mediaQuery.size.width / 2,
                                      child: const TaskListSettingsView(),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) {
                            return [
                              PopupMenuItem(
                                onTap: () => tasksCubit.clearCompletedTasks(),
                                child: const Text('Clear completed'),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
