import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';

class QuickActionsCard extends StatelessWidget {
  final AppStrings strings;
  final VoidCallback onStartTrip;
  final VoidCallback onAddManually;
  final VoidCallback onAddExpense;
  final bool isTripTracking;
  final bool isStartTripBusy;

  const QuickActionsCard({
    super.key,
    required this.strings,
    required this.onStartTrip,
    required this.onAddManually,
    required this.onAddExpense,
    this.isTripTracking = false,
    this.isStartTripBusy = false,
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
                  onPressed: isStartTripBusy ? null : onStartTrip,
                  icon: isStartTripBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(isTripTracking ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    isTripTracking ? strings.stopTracking : strings.startTrip,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onAddManually,
                  icon: const Icon(Icons.add),
                  label: Text(strings.addManually),
                ),
                OutlinedButton.icon(
                  onPressed: onAddExpense,
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
