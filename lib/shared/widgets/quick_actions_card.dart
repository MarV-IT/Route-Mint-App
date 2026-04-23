import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';

class QuickActionsCard extends StatelessWidget {
  final AppStrings strings;

  const QuickActionsCard({
    super.key,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.quickActions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: Text(strings.startTrip),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: Text(strings.addManually),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.receipt_long),
                  label: Text(strings.addExpense),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
