import 'package:flutter/material.dart';
import 'package:helpers/helpers.dart';

import '../tasks.dart';

/// Displays the sheet's name, and allows the user to change it.
class NewTaskButton extends StatefulWidget {
  const NewTaskButton({
    Key? key,
  }) : super(key: key);

  @override
  State<NewTaskButton> createState() => _NewTaskButtonState();
}

class _NewTaskButtonState extends State<NewTaskButton> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode(
    debugLabel: 'NewTaskButton FocusNode',
  );

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  bool _showTextField = false;

  @override
  Widget build(BuildContext context) {
    focusNode.addListener(() {
      // When focus is lost, switch back to showing the Text widget.
      if (!focusNode.hasFocus) setState(() => _showTextField = false);
    });

    controller.text = 'Name';

    void _createTask() {
      tasksCubit.createTask(Task(title: controller.text));
      FocusManager.instance.primaryFocus?.unfocus();
    }

    Widget child;
    if (_showTextField) {
      child = TextField(
        focusNode: focusNode,
        controller: controller..selectAll(),
        autofocus: true,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _createTask(),
      );
    } else {
      child = const Text('New Task');
    }

    return Opacity(
      opacity: _showTextField ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ListTile(
          leading: const Icon(Icons.add),
          title: child,
          onTap: () {
            focusNode.requestFocus();
            setState(() => _showTextField = true);
          },
        ),
      ),
    );
  }
}
