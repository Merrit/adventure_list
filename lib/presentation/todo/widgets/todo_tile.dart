import 'package:flutter/material.dart';

import '../../../application/home/cubit/home_cubit.dart';
import '../../../domain/domain.dart';
import '../../styles.dart';

/// A custom `ListTile` representing a single `Todo`.
class TodoTile extends StatelessWidget {
  final Todo todo;

  const TodoTile({
    Key? key,
    required this.todo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget _checkBox = Opacity(
      opacity: todo.isComplete ? 0.5 : 1.0,
      child: Padding(
        // Space between the checkbox and Todo title.
        padding: const EdgeInsets.only(right: 4),
        child: Checkbox(
          value: todo.isComplete,
          shape: const CircleBorder(),
          side: BorderSide(
            color: CustomColors.fadedColor,
          ),
          onChanged: (value) => homeCubit.updateTodo(
            todo.copyWith(isComplete: value),
          ),
        ),
      ),
    );

    final Widget _title = Flexible(
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          todo.title,
          style: TextStyle(
            color: todo.isComplete ? Colors.grey : null,
            decoration: todo.isComplete ? TextDecoration.lineThrough : null,
            fontSize: 18,
          ),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _checkBox,
        _title,
      ],
    );
  }
}
