import '../tax/tax_service.dart';
import '../../app/app.dart';

/// Stores the user's app-wide preferences, set during onboarding
/// and editable afterwards from the Profile screen.
class UserPreferences {
  final Country country;
  final String currencyCode;
  final AppUnit unit;
  final AppLanguage language;
  final bool onboardingCompleted;

  const UserPreferences({
    required this.country,
    required this.currencyCode,
    required this.unit,
    required this.language,
    required this.onboardingCompleted,
  });

  /// Default preferences before onboarding is completed.
  factory UserPreferences.defaults() => const UserPreferences(
    country: Country.usa,
    currencyCode: 'USD',
    unit: AppUnit.miles,
    language: AppLanguage.english,
    onboardingCompleted: false,
  );

  /// Derives sensible defaults from a chosen country.
  ///
  /// - United States → USD + miles
  /// - Canada        → CAD + kilometers
  factory UserPreferences.fromCountry(Country country) {
    return UserPreferences(
      country: country,
      currencyCode: country == Country.usa ? 'USD' : 'CAD',
      unit: country == Country.usa ? AppUnit.miles : AppUnit.kilometers,
      language: AppLanguage.english,
      onboardingCompleted: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'country': country.name,
    'currencyCode': currencyCode,
    'unit': unit.name,
    'language': language.name,
    'onboardingCompleted': onboardingCompleted,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        country: Country.values.firstWhere(
          (c) => c.name == json['country'],
          orElse: () => Country.usa,
        ),
        currencyCode: json['currencyCode'] as String? ?? 'USD',
        unit: AppUnit.values.firstWhere(
          (u) => u.name == json['unit'],
          orElse: () => AppUnit.miles,
        ),
        language: AppLanguage.values.firstWhere(
          (l) => l.name == json['language'],
          orElse: () => AppLanguage.english,
        ),
        onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      );

  UserPreferences copyWith({
    Country? country,
    String? currencyCode,
    AppUnit? unit,
    AppLanguage? language,
    bool? onboardingCompleted,
  }) => UserPreferences(
    country: country ?? this.country,
    currencyCode: currencyCode ?? this.currencyCode,
    unit: unit ?? this.unit,
    language: language ?? this.language,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
  );

  @override
  String toString() =>
      'UserPreferences('
      'country: $country, '
      'currencyCode: $currencyCode, '
      'unit: $unit, '
      'language: $language, '
      'onboardingCompleted: $onboardingCompleted)';
}
