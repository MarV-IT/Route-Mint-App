import '../preferences/user_preferences.dart';

class EntitlementService {
  const EntitlementService(this.preferences);

  final UserPreferences preferences;

  bool get isPro => preferences.subscriptionStatus == SubscriptionStatus.pro;

  bool get canExportUnlimitedReports => isPro;
  bool get canUseCloudBackup => isPro;
  bool get canUseAutoDetection => isPro;
  bool get canUseFuelSummaries => isPro;
  bool get canUseMonthlyCloseChecklist => isPro;
  bool get canUseMaintenanceReminders => isPro;
}
