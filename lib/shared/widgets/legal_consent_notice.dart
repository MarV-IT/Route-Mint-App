import 'package:flutter/material.dart';

import '../../core/legal/legal_links.dart';
import '../../core/localization/app_strings.dart';

/// "By continuing you agree…" with links to the Terms of Service and the
/// Privacy Policy.
///
/// Shown on the sign-in screen, the one place where an account is created or
/// the app is entered without one, so the documents are offered before any
/// data is collected.
class LegalConsentNotice extends StatelessWidget {
  const LegalConsentNotice({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = strings.currentLanguage;

    return Column(
      children: [
        Text(
          strings.legalConsentNotice,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              onPressed: () => openLegalLink(
                context,
                strings,
                LegalLinks.termsOfService(language),
              ),
              child: Text(strings.termsOfService),
            ),
            TextButton(
              onPressed: () => openLegalLink(
                context,
                strings,
                LegalLinks.privacyPolicy(language),
              ),
              child: Text(strings.privacyPolicy),
            ),
          ],
        ),
      ],
    );
  }
}
