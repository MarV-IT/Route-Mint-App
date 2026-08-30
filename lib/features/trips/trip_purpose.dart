import '../../app/app.dart';
import '../../core/localization/app_strings.dart';
import 'models/trip.dart';

/// Resolves the business purpose shown for a trip.
///
/// Auto-generated purposes are no longer persisted: storing a translated
/// string as data froze it in whatever language was active when the trip was
/// saved, so it kept showing e.g. Ukrainian text after switching the app to
/// English. They are derived here instead, and follow the current language.
///
/// Trips written by older versions still carry that frozen text, so a value
/// matching the generated wording in any supported language is re-derived as
/// well. Anything else is what the user typed and is shown verbatim.
String? displayBusinessPurpose(Trip trip, AppStrings strings) {
  final stored = trip.businessPurpose?.trim();
  final platform = trip.platformName?.trim();

  if (stored != null &&
      stored.isNotEmpty &&
      !isGeneratedPurpose(stored, platform)) {
    return stored;
  }

  if (trip.category != 'business') return null;
  return generatedPurpose(strings, platform);
}

/// The purpose text the app generates for a business trip.
String generatedPurpose(AppStrings strings, String? platformName) {
  final platform = platformName?.trim();
  return platform != null && platform.isNotEmpty
      ? strings.platformBusinessTrip(platform)
      : strings.businessTrip;
}

/// Whether [value] is app-generated wording rather than the user's own text,
/// in any of the supported languages.
bool isGeneratedPurpose(String value, String? platformName) {
  final needle = value.trim();
  if (needle.isEmpty) return false;

  final platform = platformName?.trim();
  for (final language in AppLanguage.values) {
    final strings = AppStrings(language);
    if (needle == strings.businessTrip.trim()) return true;
    if (platform != null && platform.isNotEmpty) {
      if (needle == strings.platformBusinessTrip(platform).trim()) return true;
    }
  }
  return false;
}
