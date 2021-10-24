import 'package:flutter/material.dart';

import '../../../application/home/cubit/home_cubit.dart';

class NewTodoButton extends StatelessWidget {
  const NewTodoButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: TextButton.icon(
          onPressed: () => _newTodoPrompt(context),
          icon: const Icon(Icons.add),
          label: const Text('New Todo'),
        ),
      ),
    );
  }
}

Future<void> _newTodoPrompt(BuildContext context) async {
  final controller = TextEditingController();
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: TextField(
          autofocus: true,
          controller: controller,
          onSubmitted: (_) => Navigator.pop(context),
        ),
      );
    },
  );
  final name = controller.value.text;
  if (name != '') homeCubit.createTodo(name);
}
