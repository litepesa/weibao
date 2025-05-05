import 'package:flutter/material.dart';

class AppBarBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;

  const AppBarBackButton({
    Key? key,
    this.onPressed,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios),
      color: color ?? Colors.black87,
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }
}