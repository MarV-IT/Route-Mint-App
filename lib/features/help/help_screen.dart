import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final sections = [
      _HelpSection(
        icon: Icons.route_outlined,
        title: strings.helpTrackTripsTitle,
        body: strings.helpTrackTripsBody,
      ),
      _HelpSection(
        icon: Icons.radar_outlined,
        title: strings.helpAutoDetectionTitle,
        body: strings.helpAutoDetectionBody,
      ),
      _HelpSection(
        icon: Icons.rate_review_outlined,
        title: strings.helpReviewTripsTitle,
        body: strings.helpReviewTripsBody,
      ),
      _HelpSection(
        icon: Icons.receipt_long_outlined,
        title: strings.helpExpensesFuelTitle,
        body: strings.helpExpensesFuelBody,
      ),
      _HelpSection(
        icon: Icons.picture_as_pdf_outlined,
        title: strings.helpExportReportsTitle,
        body: strings.helpExportReportsBody,
      ),
      _HelpSection(
        icon: Icons.cloud_done_outlined,
        title: strings.helpBackupAccountTitle,
        body: strings.helpBackupAccountBody,
      ),
      _HelpSection(
        icon: Icons.car_repair_outlined,
        title: strings.helpVehicleMaintenanceTitle,
        body: strings.helpVehicleMaintenanceBody,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(strings.howItWorks)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Card(
            elevation: 0,
            child: ListTile(
              leading: Icon(section.icon),
              title: Text(section.title),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(section.body),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HelpSection {
  const _HelpSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
