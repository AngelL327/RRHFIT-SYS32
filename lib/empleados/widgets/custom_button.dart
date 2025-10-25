import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final Color? bgColor;
  final Color? fgColor;
  final Icon icono;
  final String btnTitle;
  final VoidCallback? onPressed;

  const CustomButton({
    super.key,
    this.bgColor,
    this.fgColor,
    required this.icono,
    required this.btnTitle,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
      onPressed: onPressed,
      child: Row(children: [icono, const SizedBox(width: 4.0), Text(btnTitle)]),
    );
  }
}
