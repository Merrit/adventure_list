import 'package:flutter/material.dart';

class CircleButton extends StatelessWidget {
  /// Button color
  final Color color;

  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsets padding;
  final Color splashColor;

  const CircleButton({
    Key? key,
    this.color = Colors.blue,
    required this.child,
    this.onPressed,
    this.padding = const EdgeInsets.all(6.0),
    this.splashColor = Colors.pink,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          splashColor: splashColor,
          onTap: onPressed,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
