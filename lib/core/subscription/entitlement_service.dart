import '../preferences/user_preferences.dart';

class EntitlementService {
  const EntitlementService(this.preferences);

  final UserPreferences preferences;

  bool get isPro =>
      preferences.subscriptionStatus == SubscriptionStatus.pro ||
      preferences.subscriptionStatus == SubscriptionStatus.testerPro;

  bool get isTesterPro =>
      preferences.subscriptionStatus == SubscriptionStatus.testerPro;

  bool get canExportUnlimitedReports => isPro;
  bool get canUseCloudBackup => isPro;
  bool get canUseAutoDetection => isPro;
  bool get canUseFuelSummaries => isPro;
  bool get canUseMonthlyCloseChecklist => isPro;
  bool get canUseMaintenanceReminders => isPro;
}
