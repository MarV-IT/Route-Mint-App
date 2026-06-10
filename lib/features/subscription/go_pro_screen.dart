import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';

class GoProScreen extends StatelessWidget {
  const GoProScreen({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final benefits = [
      (Icons.picture_as_pdf_outlined, strings.proUnlimitedReports),
      (Icons.cloud_done_outlined, strings.proCloudBackup),
      (Icons.local_gas_station_outlined, strings.proFuelSummaries),
      (Icons.checklist_outlined, strings.proMonthlyCloseChecklist),
      (Icons.radar_outlined, strings.proAutoDetection),
      (Icons.car_repair_outlined, strings.proMaintenanceReminders),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(strings.goPro)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.unlockProTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.unlockProBody,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...benefits.map(
            (benefit) => Card(
              elevation: 0,
              child: ListTile(
                leading: Icon(benefit.$1),
                title: Text(benefit.$2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.lock_outline),
            label: Text(strings.paymentsComingSoon),
          ),
          const SizedBox(height: 8),
          Text(
            strings.testerProHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
