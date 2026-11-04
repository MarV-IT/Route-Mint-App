import '../tax/tax_service.dart';
import '../../app/app.dart';

enum SubscriptionStatus { free, pro, testerPro }

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

  /// Free-text vehicle name from before the Vehicle section existed. New
  /// saves keep it in step with [vehicleDescription] for older readers.
  final String? vehicleName;
  final String? vehicleMake;
  final String? vehicleModel;
  final int? vehicleYear;
  final String? vehicleLicensePlate;
  final bool autoTripDetectionEnabled;
  final SubscriptionStatus subscriptionStatus;
  final AppThemeMode themeMode;
  final String? accountantName;
  final String? accountantPhone;
  final String? accountantAddress;
  final String? insuranceCompanyName;
  final String? insurancePolicyName;
  final String? insurancePolicyNumber;
  final String? insuranceCompanyContact;

  /// Whether the first-run feature guide has been finished or skipped.
  final bool featureGuideCompleted;

  /// The release whose "What's new" notes were last shown and closed.
  final String? whatsNewSeenVersion;
  // Vehicle maintenance — stored in kilometres regardless of display unit.
  final double? vehicleOdometerKm;
  final double? lastOilChangeOdometerKm;
  final double? oilChangeIntervalKm;
  final double? oilChangeReminderThresholdKm;
  final double? lastBrakePadChangeOdometerKm;
  final double? brakePadChangeIntervalKm;
  final double? brakePadReminderThresholdKm;
  final DateTime? lastOdometerUpdateAt;
  final DateTime? lastAutomaticCloudBackupAt;

  const UserPreferences({
    required this.country,
    required this.currencyCode,
    required this.unit,
    required this.language,
    required this.onboardingCompleted,
    this.driverName,
    this.businessName,
    this.vehicleName,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYear,
    this.vehicleLicensePlate,
    this.autoTripDetectionEnabled = false,
    this.subscriptionStatus = SubscriptionStatus.free,
    this.themeMode = AppThemeMode.system,
    this.accountantName,
    this.accountantPhone,
    this.accountantAddress,
    this.insuranceCompanyName,
    this.insurancePolicyName,
    this.insurancePolicyNumber,
    this.insuranceCompanyContact,
    this.featureGuideCompleted = false,
    this.whatsNewSeenVersion,
    this.vehicleOdometerKm,
    this.lastOilChangeOdometerKm,
    this.oilChangeIntervalKm,
    this.oilChangeReminderThresholdKm,
    this.lastBrakePadChangeOdometerKm,
    this.brakePadChangeIntervalKm,
    this.brakePadReminderThresholdKm,
    this.lastOdometerUpdateAt,
    this.lastAutomaticCloudBackupAt,
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
    'vehicleMake': vehicleMake,
    'vehicleModel': vehicleModel,
    'vehicleYear': vehicleYear,
    'vehicleLicensePlate': vehicleLicensePlate,
    'autoTripDetectionEnabled': autoTripDetectionEnabled,
    'subscriptionStatus': subscriptionStatus.name,
    'themeMode': themeMode.name,
    'accountantName': accountantName,
    'accountantPhone': accountantPhone,
    'accountantAddress': accountantAddress,
    'insuranceCompanyName': insuranceCompanyName,
    'insurancePolicyName': insurancePolicyName,
    'insurancePolicyNumber': insurancePolicyNumber,
    'insuranceCompanyContact': insuranceCompanyContact,
    'featureGuideCompleted': featureGuideCompleted,
    'whatsNewSeenVersion': whatsNewSeenVersion,
    'vehicleOdometerKm': vehicleOdometerKm,
    'lastOilChangeOdometerKm': lastOilChangeOdometerKm,
    'oilChangeIntervalKm': oilChangeIntervalKm,
    'oilChangeReminderThresholdKm': oilChangeReminderThresholdKm,
    'lastBrakePadChangeOdometerKm': lastBrakePadChangeOdometerKm,
    'brakePadChangeIntervalKm': brakePadChangeIntervalKm,
    'brakePadReminderThresholdKm': brakePadReminderThresholdKm,
    'lastOdometerUpdateAt': lastOdometerUpdateAt?.toIso8601String(),
    'lastAutomaticCloudBackupAt': lastAutomaticCloudBackupAt?.toIso8601String(),
  };

  factory UserPreferences.fromJson(
    Map<String, dynamic> json,
  ) => UserPreferences(
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
    vehicleMake: _stringOrNull(json['vehicleMake']),
    vehicleModel: _stringOrNull(json['vehicleModel']),
    vehicleYear: json['vehicleYear'] is int ? json['vehicleYear'] as int : null,
    vehicleLicensePlate: _stringOrNull(json['vehicleLicensePlate']),
    autoTripDetectionEnabled: json['autoTripDetectionEnabled'] is bool
        ? json['autoTripDetectionEnabled'] as bool
        : false,
    subscriptionStatus: SubscriptionStatus.values.firstWhere(
      (s) => s.name == json['subscriptionStatus'],
      orElse: () => SubscriptionStatus.free,
    ),
    themeMode: AppThemeMode.values.firstWhere(
      (t) => t.name == json['themeMode'],
      orElse: () => AppThemeMode.system,
    ),
    accountantName: _stringOrNull(json['accountantName']),
    accountantPhone: _stringOrNull(json['accountantPhone']),
    accountantAddress: _stringOrNull(json['accountantAddress']),
    insuranceCompanyName: _stringOrNull(json['insuranceCompanyName']),
    insurancePolicyName: _stringOrNull(json['insurancePolicyName']),
    insurancePolicyNumber: _stringOrNull(json['insurancePolicyNumber']),
    insuranceCompanyContact: _stringOrNull(json['insuranceCompanyContact']),
    // Saved before the guide existed: anyone already set up has seen
    // the app, so only brand-new users get the guide.
    featureGuideCompleted: json['featureGuideCompleted'] is bool
        ? json['featureGuideCompleted'] as bool
        : json['onboardingCompleted'] == true,
    whatsNewSeenVersion: _stringOrNull(json['whatsNewSeenVersion']),
    vehicleOdometerKm: _doubleOrNull(json['vehicleOdometerKm']),
    lastOilChangeOdometerKm: _doubleOrNull(json['lastOilChangeOdometerKm']),
    oilChangeIntervalKm: _doubleOrNull(json['oilChangeIntervalKm']),
    oilChangeReminderThresholdKm: _doubleOrNull(
      json['oilChangeReminderThresholdKm'],
    ),
    lastBrakePadChangeOdometerKm: _doubleOrNull(
      json['lastBrakePadChangeOdometerKm'],
    ),
    brakePadChangeIntervalKm: _doubleOrNull(json['brakePadChangeIntervalKm']),
    brakePadReminderThresholdKm: _doubleOrNull(
      json['brakePadReminderThresholdKm'],
    ),
    lastOdometerUpdateAt: json['lastOdometerUpdateAt'] is String
        ? _parseLocalDateTime(json['lastOdometerUpdateAt'] as String)
        : null,
    lastAutomaticCloudBackupAt: json['lastAutomaticCloudBackupAt'] is String
        ? _parseLocalDateTime(json['lastAutomaticCloudBackupAt'] as String)
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
    Object? vehicleMake = _sentinel,
    Object? vehicleModel = _sentinel,
    Object? vehicleYear = _sentinel,
    Object? vehicleLicensePlate = _sentinel,
    bool? autoTripDetectionEnabled,
    SubscriptionStatus? subscriptionStatus,
    AppThemeMode? themeMode,
    Object? accountantName = _sentinel,
    Object? accountantPhone = _sentinel,
    Object? accountantAddress = _sentinel,
    Object? insuranceCompanyName = _sentinel,
    Object? insurancePolicyName = _sentinel,
    Object? insurancePolicyNumber = _sentinel,
    Object? insuranceCompanyContact = _sentinel,
    bool? featureGuideCompleted,
    Object? whatsNewSeenVersion = _sentinel,
    Object? vehicleOdometerKm = _sentinel,
    Object? lastOilChangeOdometerKm = _sentinel,
    Object? oilChangeIntervalKm = _sentinel,
    Object? oilChangeReminderThresholdKm = _sentinel,
    Object? lastBrakePadChangeOdometerKm = _sentinel,
    Object? brakePadChangeIntervalKm = _sentinel,
    Object? brakePadReminderThresholdKm = _sentinel,
    Object? lastOdometerUpdateAt = _sentinel,
    Object? lastAutomaticCloudBackupAt = _sentinel,
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
    vehicleMake: vehicleMake == _sentinel
        ? this.vehicleMake
        : vehicleMake as String?,
    vehicleModel: vehicleModel == _sentinel
        ? this.vehicleModel
        : vehicleModel as String?,
    vehicleYear: vehicleYear == _sentinel
        ? this.vehicleYear
        : vehicleYear as int?,
    vehicleLicensePlate: vehicleLicensePlate == _sentinel
        ? this.vehicleLicensePlate
        : vehicleLicensePlate as String?,
    autoTripDetectionEnabled:
        autoTripDetectionEnabled ?? this.autoTripDetectionEnabled,
    subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
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
    insurancePolicyName: insurancePolicyName == _sentinel
        ? this.insurancePolicyName
        : insurancePolicyName as String?,
    insurancePolicyNumber: insurancePolicyNumber == _sentinel
        ? this.insurancePolicyNumber
        : insurancePolicyNumber as String?,
    insuranceCompanyContact: insuranceCompanyContact == _sentinel
        ? this.insuranceCompanyContact
        : insuranceCompanyContact as String?,
    featureGuideCompleted: featureGuideCompleted ?? this.featureGuideCompleted,
    whatsNewSeenVersion: whatsNewSeenVersion == _sentinel
        ? this.whatsNewSeenVersion
        : whatsNewSeenVersion as String?,
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
    lastAutomaticCloudBackupAt: lastAutomaticCloudBackupAt == _sentinel
        ? this.lastAutomaticCloudBackupAt
        : lastAutomaticCloudBackupAt as DateTime?,
  );

  /// The vehicle as reports name it, e.g. "2021 Toyota Camry · ABC 1234".
  /// Falls back to the older free-text [vehicleName] until the structured
  /// fields are filled in.
  String? get vehicleDescription {
    final car = [
      if (vehicleYear != null) '$vehicleYear',
      if (vehicleMake?.trim().isNotEmpty == true) vehicleMake!.trim(),
      if (vehicleModel?.trim().isNotEmpty == true) vehicleModel!.trim(),
    ].join(' ');
    final plate = vehicleLicensePlate?.trim() ?? '';
    final parts = [if (car.isNotEmpty) car, if (plate.isNotEmpty) plate];
    if (parts.isNotEmpty) return parts.join(' · ');
    final legacy = vehicleName?.trim();
    return legacy == null || legacy.isEmpty ? null : legacy;
  }

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
      'autoTripDetectionEnabled: $autoTripDetectionEnabled, '
      'subscriptionStatus: $subscriptionStatus)';
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
