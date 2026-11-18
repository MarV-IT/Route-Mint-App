import '../../core/localization/app_strings.dart';
import '../../core/subscription/subscription_models.dart';

/// Wording shared by the Pro screen and the Subscription section of Profile.

/// Year first, so the date reads the same to US and Canadian drivers.
String subscriptionDate(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}

/// What happens next with an active subscription: a renewal, an end date
/// after cancelling, or the end of the trial. Null when access has no date.
String? subscriptionNextStep(SubscriptionState state, AppStrings s) {
  final end = state.expiresAt;
  if (end == null) return null;
  final date = subscriptionDate(end);
  if (!state.willRenew) return s.proEndsOn(date);
  if (state.inTrial) return s.proTrialUntil(date);
  return s.proRenewsOn(date);
}

String? planName(PlanPeriod? period, AppStrings s) => switch (period) {
  PlanPeriod.annual => s.proPlanAnnual,
  PlanPeriod.monthly => s.proPlanMonthly,
  PlanPeriod.other || null => null,
};

String trialLength(FreeTrial trial, AppStrings s) => switch (trial.unit) {
  TrialUnit.day => s.trialDays(trial.count),
  TrialUnit.week => s.trialWeeks(trial.count),
  TrialUnit.month => s.trialMonths(trial.count),
  TrialUnit.year => s.trialYears(trial.count),
};

/// Store names are brands and stay untranslated.
String? storeName(SubscriptionStore store) => switch (store) {
  SubscriptionStore.appStore => 'App Store',
  SubscriptionStore.playStore => 'Google Play',
  SubscriptionStore.other => null,
};

/// Google Play's own page for redeeming [code]; it fills the code in.
Uri playRedeemUri(String code) =>
    Uri.https('play.google.com', '/redeem', {'code': code.trim()});

/// A plan's price with its period, e.g. "$39.99 / year".
String planPrice(SubscriptionPlan plan, AppStrings s) => switch (plan.period) {
  PlanPeriod.annual => s.pricePerYear(plan.priceText),
  PlanPeriod.monthly => s.pricePerMonth(plan.priceText),
  PlanPeriod.other => plan.priceText,
};

/// Whole percent saved by paying for [annual] instead of twelve [monthly]
/// periods, or null when there is nothing worth advertising.
int? annualSavingsPercent(SubscriptionPlan annual, SubscriptionPlan monthly) {
  if (annual.currencyCode != monthly.currencyCode) return null;
  final yearOfMonths = monthly.price * 12;
  if (yearOfMonths <= 0 || annual.price <= 0) return null;
  // Rounded down: the badge must never promise more than the real saving.
  final percent = ((1 - annual.price / yearOfMonths) * 100).floor();
  return percent >= 5 ? percent : null;
}
