import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/location/location_permission_service.dart';
import '../../core/storage/account_data_store.dart';

/// Checks location access for a tracking feature and, whenever the system
/// permission prompt is about to appear, first explains what the app does
/// with location.
///
/// The stores require this explanation to be shown inside the app, before
/// the system prompt, because trips keep recording while the app is in the
/// background. If the user declines it, the system prompt is not shown and
/// [LocationPermissionStatus.denied] is returned, exactly as if the
/// permission had been refused.
Future<LocationPermissionStatus> requestLocationWithDisclosure(
  BuildContext context, {
  required AppStrings strings,
  required LocationPermissionService permissionService,
}) async {
  final scope = AccountDataStore.current;
  bool isCurrent() =>
      context.mounted && identical(scope, AccountDataStore.current);
  if (!isCurrent()) return LocationPermissionStatus.denied;
  return permissionService.checkAndRequest(
    beforePermissionRequest: () async {
      if (!isCurrent()) return false;
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          // Title and text scroll together: at large text sizes they are
          // taller than a small phone, and the buttons must stay reachable.
          scrollable: true,
          icon: const Icon(Icons.location_on_outlined),
          title: Text(strings.locationDisclosureTitle),
          content: Text(strings.locationDisclosureBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.notNow),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.continueAction),
            ),
          ],
        ),
      );
      return accepted == true && isCurrent();
    },
  );
}
