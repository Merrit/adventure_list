import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../tasks.dart';

class TaskDetails extends StatelessWidget {
  static const routeName = 'task_details';

  const TaskDetails({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final Task? task = state.activeTask;

        return Expanded(
          child: Card(
            margin: const EdgeInsets.all(6),
            child: Stack(
              alignment: AlignmentDirectional.topCenter,
              children: task == null
                  ? []
                  : [
                      PositionedDirectional(
                        end: 5,
                        child: Card(
                          color: Colors.grey.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => tasksCubit.setActiveTask(null),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(task.title),
                        ],
                      ),
                    ],
            ),
          ),
        );
      },
    );
  }
}
