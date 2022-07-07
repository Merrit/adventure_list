import 'package:flutter/material.dart';
import 'package:helpers/helpers.dart';

import '../tasks.dart';

/// Button for creating new tasks.
///
/// Initially a less emphasized `ListTile`, when clicked the title becomes a
/// TextField so the user can enter a name for the new task; when the user is
/// finished entering the new name it transforms back into the base widget
/// version of itself to be used again.
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

// TODO: Can we genericize this widget pattern? Widget -> TextField -> Widget
//
// Doesn't work in this instance, because we only want the ListTile's title to
// be replaced by TextField, but have the entire ListTile be clickable to enter
// TextField mode. Need to experiment with this more.
//
/// Widget which when clicked becomes a `TextField`, and when submitted calls
/// `onSubmitted` with the entered text and becomes the originally provided
/// widget again.
// class TextFieldSwapWidget extends StatefulWidget {
//   final Widget defaultChild;
//   final FocusNode? focusNode;
//   final void Function(String value) onSubmitted;
//   final TextAlign? textAlign;
//   final String? textFieldInitialText;

//   const TextFieldSwapWidget({
//     Key? key,
//     required this.defaultChild,
//     this.focusNode,
//     required this.onSubmitted,
//     this.textAlign,
//     this.textFieldInitialText,
//   }) : super(key: key);

//   @override
//   State<TextFieldSwapWidget> createState() => _TextFieldSwapWidgetState();
// }

// class _TextFieldSwapWidgetState extends State<TextFieldSwapWidget> {
//   final TextEditingController controller = TextEditingController();
//   late final FocusNode focusNode;

//   @override
//   void initState() {
//     focusNode = widget.focusNode ??
//         FocusNode(
//           debugLabel: 'TextFieldSwapWidget FocusNode',
//         )
//       ..addListener(() {
//         // When focus is lost, switch back to showing the Text widget.
//         print('focus listener triggered');
//         if (focusNode.hasFocus) {
//           setState(() => _showTextField = true);
//         } else {
//           setState(() => _showTextField = false);
//         }
//       });
//     super.initState();
//   }

//   @override
//   void dispose() {
//     controller.dispose();
//     focusNode.dispose();
//     super.dispose();
//   }

//   bool _showTextField = false;

//   @override
//   Widget build(BuildContext context) {
//     // focusNode.addListener(() {
//     //   // When focus is lost, switch back to showing the Text widget.
//     //   print('focus listener triggered');
//     //   if (focusNode.hasFocus) {
//     //     setState(() => _showTextField = true);
//     //   } else {
//     //     setState(() => _showTextField = false);
//     //   }
//     // });

//     controller.text = widget.textFieldInitialText ?? '';

//     void _submit() {
//       widget.onSubmitted(controller.text);
//       FocusManager.instance.primaryFocus?.unfocus();
//     }

//     Widget child;
//     if (_showTextField) {
//       child = TextField(
//         focusNode: focusNode,
//         controller: controller..selectAll(),
//         autofocus: true,
//         textAlign: widget.textAlign ?? TextAlign.start,
//         textAlignVertical: TextAlignVertical.center,
//         keyboardType: TextInputType.text,
//         textCapitalization: TextCapitalization.words,
//         onSubmitted: (_) => _submit(),
//       );
//     } else {
//       child = widget.defaultChild;
//     }

//     return InkWell(
//       onTap: () {
//         focusNode.requestFocus();
//         setState(() => _showTextField = true);
//       },
//       child: child,
//     );
//   }
// }
