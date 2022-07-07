import 'package:flutter/material.dart';

class CircleButton extends StatelessWidget {
  /// Button color
  final Color? color;

  final Widget child;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onPressed;

  const CircleButton({
    Key? key,
    this.color,
    required this.child,
    this.elevation,
    this.margin,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      color: color,
      margin: margin,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: IconButton(
        icon: child,
        onPressed: onPressed,
      ),
    );
  }
}
