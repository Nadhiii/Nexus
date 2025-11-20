import 'package:flutter/material.dart';
import '../../core/models/goal.dart';

class GoalTrackerWidget extends StatelessWidget {
  final Goal goal;

  const GoalTrackerWidget({Key? key, required this.goal}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${goal.currentAmount.toStringAsFixed(0)}', style: textTheme.bodySmall),
                Text('₹${goal.targetAmount.toStringAsFixed(0)}', style: textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: goal.progressPercentage / 100,
              backgroundColor: colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '${goal.progressPercentage.toStringAsFixed(1)}% complete',
              style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
