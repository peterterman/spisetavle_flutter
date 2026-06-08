import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';

class NutrientRow extends StatelessWidget {
  final String name;
  final String value;
  final String goal;
  final double progress;

  const NutrientRow({
    super.key,
    required this.name,
    required this.value,
    required this.goal,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0);

    Color barColor;

    if (progress < 0.80) {
      barColor = const Color(0xFFB08A5A); // brun
    } else if (progress <= 1.00) {
      barColor = Colors.green;
    } else {
      barColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(name, style: TextStyle(fontSize: AppSizes.normal)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: safeProgress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 55,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: AppSizes.normal,
                color: progress > 1.0 ? Colors.red : Colors.black,
                fontWeight: progress > 1.0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              goal,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: AppSizes.normal),
            ),
          ),
        ],
      ),
    );
  }
}
