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
  final String? driverName;
  final String? businessName;
  final String? vehicleName;
  final bool autoTripDetectionEnabled;
  final AppThemeMode themeMode;
  final String? accountantName;
  final String? accountantPhone;
  final String? accountantAddress;
  final String? insuranceCompanyName;
  final String? insurancePolicyNumber;
  final String? insuranceCompanyContact;
  // Vehicle maintenance — stored in kilometres regardless of display unit.
  final double? vehicleOdometerKm;
  final double? lastOilChangeOdometerKm;
  final double? oilChangeIntervalKm;
  final double? oilChangeReminderThresholdKm;
  final double? lastBrakePadChangeOdometerKm;
  final double? brakePadChangeIntervalKm;
  final double? brakePadReminderThresholdKm;
  final DateTime? lastOdometerUpdateAt;

  const UserPreferences({
    required this.country,
    required this.currencyCode,
    required this.unit,
    required this.language,
    required this.onboardingCompleted,
    this.driverName,
    this.businessName,
    this.vehicleName,
    this.autoTripDetectionEnabled = false,
    this.themeMode = AppThemeMode.system,
    this.accountantName,
    this.accountantPhone,
    this.accountantAddress,
    this.insuranceCompanyName,
    this.insurancePolicyNumber,
    this.insuranceCompanyContact,
    this.vehicleOdometerKm,
    this.lastOilChangeOdometerKm,
    this.oilChangeIntervalKm,
    this.oilChangeReminderThresholdKm,
    this.lastBrakePadChangeOdometerKm,
    this.brakePadChangeIntervalKm,
    this.brakePadReminderThresholdKm,
    this.lastOdometerUpdateAt,
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
    'driverName': driverName,
    'businessName': businessName,
    'vehicleName': vehicleName,
    'autoTripDetectionEnabled': autoTripDetectionEnabled,
    'themeMode': themeMode.name,
    'accountantName': accountantName,
    'accountantPhone': accountantPhone,
    'accountantAddress': accountantAddress,
    'insuranceCompanyName': insuranceCompanyName,
    'insurancePolicyNumber': insurancePolicyNumber,
    'insuranceCompanyContact': insuranceCompanyContact,
    'vehicleOdometerKm': vehicleOdometerKm,
    'lastOilChangeOdometerKm': lastOilChangeOdometerKm,
    'oilChangeIntervalKm': oilChangeIntervalKm,
    'oilChangeReminderThresholdKm': oilChangeReminderThresholdKm,
    'lastBrakePadChangeOdometerKm': lastBrakePadChangeOdometerKm,
    'brakePadChangeIntervalKm': brakePadChangeIntervalKm,
    'brakePadReminderThresholdKm': brakePadReminderThresholdKm,
    'lastOdometerUpdateAt': lastOdometerUpdateAt?.toIso8601String(),
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        country: Country.values.firstWhere(
          (c) => c.name == json['country'],
          orElse: () => Country.usa,
        ),
        currencyCode: json['currencyCode'] is String
            ? json['currencyCode'] as String
            : 'USD',
        unit: AppUnit.values.firstWhere(
          (u) => u.name == json['unit'],
          orElse: () => AppUnit.miles,
        ),
        language: AppLanguage.values.firstWhere(
          (l) => l.name == json['language'],
          orElse: () => AppLanguage.english,
        ),
        onboardingCompleted: json['onboardingCompleted'] is bool
            ? json['onboardingCompleted'] as bool
            : false,
        driverName: _stringOrNull(json['driverName']),
        businessName: _stringOrNull(json['businessName']),
        vehicleName: _stringOrNull(json['vehicleName']),
        autoTripDetectionEnabled: json['autoTripDetectionEnabled'] is bool
            ? json['autoTripDetectionEnabled'] as bool
            : false,
        themeMode: AppThemeMode.values.firstWhere(
          (t) => t.name == json['themeMode'],
          orElse: () => AppThemeMode.system,
        ),
        accountantName: _stringOrNull(json['accountantName']),
        accountantPhone: _stringOrNull(json['accountantPhone']),
        accountantAddress: _stringOrNull(json['accountantAddress']),
        insuranceCompanyName: _stringOrNull(json['insuranceCompanyName']),
        insurancePolicyNumber: _stringOrNull(json['insurancePolicyNumber']),
        insuranceCompanyContact: _stringOrNull(json['insuranceCompanyContact']),
        vehicleOdometerKm: _doubleOrNull(json['vehicleOdometerKm']),
        lastOilChangeOdometerKm: _doubleOrNull(json['lastOilChangeOdometerKm']),
        oilChangeIntervalKm: _doubleOrNull(json['oilChangeIntervalKm']),
        oilChangeReminderThresholdKm: _doubleOrNull(
          json['oilChangeReminderThresholdKm'],
        ),
        lastBrakePadChangeOdometerKm: _doubleOrNull(
          json['lastBrakePadChangeOdometerKm'],
        ),
        brakePadChangeIntervalKm: _doubleOrNull(
          json['brakePadChangeIntervalKm'],
        ),
        brakePadReminderThresholdKm: _doubleOrNull(
          json['brakePadReminderThresholdKm'],
        ),
        lastOdometerUpdateAt: json['lastOdometerUpdateAt'] is String
            ? _parseLocalDateTime(json['lastOdometerUpdateAt'] as String)
            : null,
      );

  UserPreferences copyWith({
    Country? country,
    String? currencyCode,
    AppUnit? unit,
    AppLanguage? language,
    bool? onboardingCompleted,
    Object? driverName = _sentinel,
    Object? businessName = _sentinel,
    Object? vehicleName = _sentinel,
    bool? autoTripDetectionEnabled,
    AppThemeMode? themeMode,
    Object? accountantName = _sentinel,
    Object? accountantPhone = _sentinel,
    Object? accountantAddress = _sentinel,
    Object? insuranceCompanyName = _sentinel,
    Object? insurancePolicyNumber = _sentinel,
    Object? insuranceCompanyContact = _sentinel,
    Object? vehicleOdometerKm = _sentinel,
    Object? lastOilChangeOdometerKm = _sentinel,
    Object? oilChangeIntervalKm = _sentinel,
    Object? oilChangeReminderThresholdKm = _sentinel,
    Object? lastBrakePadChangeOdometerKm = _sentinel,
    Object? brakePadChangeIntervalKm = _sentinel,
    Object? brakePadReminderThresholdKm = _sentinel,
    Object? lastOdometerUpdateAt = _sentinel,
  }) => UserPreferences(
    country: country ?? this.country,
    currencyCode: currencyCode ?? this.currencyCode,
    unit: unit ?? this.unit,
    language: language ?? this.language,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    driverName: driverName == _sentinel
        ? this.driverName
        : driverName as String?,
    businessName: businessName == _sentinel
        ? this.businessName
        : businessName as String?,
    vehicleName: vehicleName == _sentinel
        ? this.vehicleName
        : vehicleName as String?,
    autoTripDetectionEnabled:
        autoTripDetectionEnabled ?? this.autoTripDetectionEnabled,
    themeMode: themeMode ?? this.themeMode,
    accountantName: accountantName == _sentinel
        ? this.accountantName
        : accountantName as String?,
    accountantPhone: accountantPhone == _sentinel
        ? this.accountantPhone
        : accountantPhone as String?,
    accountantAddress: accountantAddress == _sentinel
        ? this.accountantAddress
        : accountantAddress as String?,
    insuranceCompanyName: insuranceCompanyName == _sentinel
        ? this.insuranceCompanyName
        : insuranceCompanyName as String?,
    insurancePolicyNumber: insurancePolicyNumber == _sentinel
        ? this.insurancePolicyNumber
        : insurancePolicyNumber as String?,
    insuranceCompanyContact: insuranceCompanyContact == _sentinel
        ? this.insuranceCompanyContact
        : insuranceCompanyContact as String?,
    vehicleOdometerKm: vehicleOdometerKm == _sentinel
        ? this.vehicleOdometerKm
        : vehicleOdometerKm as double?,
    lastOilChangeOdometerKm: lastOilChangeOdometerKm == _sentinel
        ? this.lastOilChangeOdometerKm
        : lastOilChangeOdometerKm as double?,
    oilChangeIntervalKm: oilChangeIntervalKm == _sentinel
        ? this.oilChangeIntervalKm
        : oilChangeIntervalKm as double?,
    oilChangeReminderThresholdKm: oilChangeReminderThresholdKm == _sentinel
        ? this.oilChangeReminderThresholdKm
        : oilChangeReminderThresholdKm as double?,
    lastBrakePadChangeOdometerKm: lastBrakePadChangeOdometerKm == _sentinel
        ? this.lastBrakePadChangeOdometerKm
        : lastBrakePadChangeOdometerKm as double?,
    brakePadChangeIntervalKm: brakePadChangeIntervalKm == _sentinel
        ? this.brakePadChangeIntervalKm
        : brakePadChangeIntervalKm as double?,
    brakePadReminderThresholdKm: brakePadReminderThresholdKm == _sentinel
        ? this.brakePadReminderThresholdKm
        : brakePadReminderThresholdKm as double?,
    lastOdometerUpdateAt: lastOdometerUpdateAt == _sentinel
        ? this.lastOdometerUpdateAt
        : lastOdometerUpdateAt as DateTime?,
  );

  @override
  String toString() =>
      'UserPreferences('
      'country: $country, '
      'currencyCode: $currencyCode, '
      'unit: $unit, '
      'language: $language, '
      'onboardingCompleted: $onboardingCompleted, '
      'driverName: $driverName, '
      'businessName: $businessName, '
      'vehicleName: $vehicleName, '
      'autoTripDetectionEnabled: $autoTripDetectionEnabled)';
}

const Object _sentinel = Object();

String? _stringOrNull(Object? value) => value is String ? value : null;

double? _doubleOrNull(Object? value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _parseLocalDateTime(String value) =>
    DateTime.tryParse(value)?.toLocal();
