import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app.dart';
import '../localization/app_strings.dart';

/// Addresses of the legal documents on marvroute.com.
///
/// The site publishes them in English, Ukrainian and French, and `?lang=`
/// opens a page in that language. French matters for Québec, where the
/// contract has to be offered in French first; the other app languages fall
/// back to English.
class LegalLinks {
  const LegalLinks._();

  static const _site = 'https://marvroute.com';

  static Uri privacyPolicy(AppLanguage language) => _page('privacy', language);

  static Uri termsOfService(AppLanguage language) => _page('terms', language);

  static Uri _page(String path, AppLanguage language) {
    final code = switch (language) {
      AppLanguage.french => 'fr',
      AppLanguage.ukrainian => 'uk',
      AppLanguage.english ||
      AppLanguage.spanish ||
      AppLanguage.russian ||
      AppLanguage.dari => 'en',
    };
    return Uri.parse('$_site/$path/?lang=$code');
  }
}

/// Opens a legal document in the browser.
///
/// If nothing on the device can open it, the address is shown instead so it
/// can still be read and typed elsewhere.
Future<void> openLegalLink(
  BuildContext context,
  AppStrings strings,
  Uri uri,
) async {
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[LegalLinks] could not open $uri: $e');
    }
  }
  if (opened) return;
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${strings.couldNotOpenLink} $uri')),
  );
}
