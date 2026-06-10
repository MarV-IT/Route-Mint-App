import 'package:flutter/material.dart';

import '../../features/subscription/go_pro_screen.dart';
import '../localization/app_strings.dart';

Future<void> openGoProScreen(BuildContext context, AppStrings strings) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => GoProScreen(strings: strings)),
  );
}

bool requireProFeature({
  required BuildContext context,
  required AppStrings strings,
  required bool allowed,
}) {
  if (allowed) return true;
  openGoProScreen(context, strings);
  return false;
}

class ProLockedCard extends StatelessWidget {
  const ProLockedCard({
    super.key,
    required this.strings,
    required this.title,
    this.icon = Icons.workspace_premium_outlined,
  });

  final AppStrings strings;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _ProBadge(strings: strings),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              strings.unlockProBody,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => openGoProScreen(context, strings),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: Text(strings.goPro),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        strings.pro,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
