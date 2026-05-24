import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/maintenance/oil_change_service.dart';
import '../../core/preferences/user_preferences.dart';
import '../../shared/utils/distance_utils.dart';
import '../../app/app.dart';

class OilChangeCard extends StatelessWidget {
  const OilChangeCard({
    super.key,
    required this.strings,
    required this.preferences,
    required this.unit,
  });

  final AppStrings strings;
  final UserPreferences preferences;
  final AppUnit unit;

  @override
  Widget build(BuildContext context) {
    final service = OilChangeService();
    final remaining = service.distanceUntilOilChangeKm(preferences);
    if (remaining == null) return const SizedBox.shrink();

    final isDue = service.isOilChangeDue(preferences);
    final isSoon = service.shouldWarnOilChangeSoon(preferences);
    final colorScheme = Theme.of(context).colorScheme;

    final Color cardColor;
    final Color textColor;
    final String title;
    final String subtitle;

    if (isDue) {
      cardColor = colorScheme.errorContainer;
      textColor = colorScheme.onErrorContainer;
      title = strings.oilChangeDue;
      subtitle = strings.oilChangeDueNow;
    } else {
      final displayDist = fromKilometers(remaining, unit);
      final distStr =
          '${strings.oilChangeDueIn} ${displayDist.toStringAsFixed(0)} ${unitLabel(unit)}';
      if (isSoon) {
        cardColor = colorScheme.tertiaryContainer;
        textColor = colorScheme.onTertiaryContainer;
        title = strings.oilChangeSoon;
        subtitle = distStr;
      } else {
        cardColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurface;
        title = strings.oilChange;
        subtitle = distStr;
      }
    }

    return Card(
      elevation: 0,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.oil_barrel_outlined, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: textColor),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: textColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
