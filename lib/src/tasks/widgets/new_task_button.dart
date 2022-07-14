import 'package:flutter/material.dart';

import '../tasks.dart';

/// Button for creating new tasks.
class NewTaskButton extends StatefulWidget {
  const NewTaskButton({
    Key? key,
  }) : super(key: key);

  @override
  State<NewTaskButton> createState() => _NewTaskButtonState();
}

class _NewTaskButtonState extends State<NewTaskButton> {
  final TextEditingController controller = TextEditingController()
    ..text = 'New Task';
  final FocusNode focusNode = FocusNode(
    debugLabel: 'NewTaskButton FocusNode',
  );

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  double opacity = 0.5;

  @override
  Widget build(BuildContext context) {
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setState(() => opacity = 1.0);
        controller.text = '';
      } else {
        setState(() => opacity = 0.5);
        controller.text = 'New Task';
      }
    });

    void _createTask() {
      if (controller.text.trim() == '') return;

      tasksCubit.createTask(Task(title: controller.text));
      FocusManager.instance.primaryFocus?.unfocus();
    }

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: const InputDecorationTheme(
              border: InputBorder.none,
            ),
          ),
          child: ListTile(
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            leading: const Icon(Icons.add),
            // title: child,
            title: TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _createTask(),
            ),
            onTap: () {
              focusNode.requestFocus();
            },
          ),
        ),
      ),
    );
  }
}
