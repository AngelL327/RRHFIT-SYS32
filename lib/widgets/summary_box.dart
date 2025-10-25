import 'package:flutter/material.dart';

class SummaryBox extends StatelessWidget {
  const SummaryBox({super.key, required this.title, required this.number, required this.color});

  final String title;
  final String number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      constraints: const BoxConstraints(minWidth: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
        border: Border.all(color: Colors.black54, width: 2),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title: give a max width and let FittedBox scale down if needed
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Number: constrained to avoid overflow and scaled when needed
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              number,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
      ],
    ),
  );
}
}
