import 'account_data_store.dart';
import '../../app/app.dart';
import '../tax/tax_service.dart';

class SettingsService {
  SettingsService({AccountDataScope? scope})
    : _scope = scope ?? AccountDataStore.current;

  final AccountDataScope _scope;
  static const String _unitKey = 'app_unit';
  static const String _languageKey = 'app_language';
  static const String _countryKey = 'app_country';

  // ─── Unit ────────────────────────────────────────────────────────────────

  Future<void> saveUnit(AppUnit unit) async {
    final prefs = await _scope.getPreferences();
    await prefs.setString(_unitKey, unit.name);
  }

  Future<AppUnit> loadUnit() async {
    final prefs = await _scope.getPreferences();
    final value = prefs.getString(_unitKey);
    if (value == null) return AppUnit.kilometers;
    return AppUnit.values.firstWhere(
      (u) => u.name == value,
      orElse: () => AppUnit.kilometers,
    );
  }

  // ─── Language ─────────────────────────────────────────────────────────────

  Future<void> saveLanguage(AppLanguage language) async {
    final prefs = await _scope.getPreferences();
    await prefs.setString(_languageKey, language.name);
  }

  Future<AppLanguage> loadLanguage() async {
    final prefs = await _scope.getPreferences();
    final value = prefs.getString(_languageKey);
    if (value == null) return AppLanguage.english;
    return AppLanguage.values.firstWhere(
      (l) => l.name == value,
      orElse: () => AppLanguage.english,
    );
  }

  // ─── Country ──────────────────────────────────────────────────────────────

  Future<void> saveCountry(Country country) async {
    final prefs = await _scope.getPreferences();
    await prefs.setString(_countryKey, country.name);
  }

  Future<Country> loadCountry() async {
    final prefs = await _scope.getPreferences();
    final value = prefs.getString(_countryKey);
    if (value == null) return Country.usa;
    return Country.values.firstWhere(
      (c) => c.name == value,
      orElse: () => Country.usa,
    );
  }
}
