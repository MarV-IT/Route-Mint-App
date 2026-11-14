/// How often a plan bills.
enum PlanPeriod { monthly, annual, other }

/// Where the active subscription was bought, which decides where it is
/// managed and cancelled.
enum SubscriptionStore { appStore, playStore, other }

enum TrialUnit { day, week, month, year }

/// A free period the store gives this customer before the first charge.
class FreeTrial {
  const FreeTrial(this.count, this.unit);

  final int count;
  final TrialUnit unit;

  @override
  bool operator ==(Object other) =>
      other is FreeTrial && other.count == count && other.unit == unit;

  @override
  int get hashCode => Object.hash(count, unit);
}

/// One way to buy Pro, as the store offers it to this customer.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.period,
    required this.priceText,
    required this.price,
    required this.currencyCode,
    this.monthlyPriceText,
    this.trial,
  });

  /// The store connection's handle for buying this plan.
  final String id;
  final PlanPeriod period;

  /// Price for one period, formatted by the store in the customer's
  /// currency. The app holds no prices of its own.
  final String priceText;
  final double price;
  final String currencyCode;

  /// What a longer plan works out to per month, formatted by the store.
  final String? monthlyPriceText;

  /// Set only when this customer can still get the trial.
  final FreeTrial? trial;
}

/// What the store last confirmed about this customer's Pro subscription.
class SubscriptionState {
  const SubscriptionState({
    required this.entitled,
    this.period,
    this.expiresAt,
    this.willRenew = false,
    this.inTrial = false,
    this.hasBillingIssue = false,
    this.store = SubscriptionStore.other,
    this.managementUrl,
    this.checkedAt,
  });

  /// Nothing bought, or nothing known yet.
  static const none = SubscriptionState(entitled: false);

  /// Pro was active when the store was last asked ([checkedAt]).
  final bool entitled;
  final PlanPeriod? period;

  /// End of the period already paid for. Null when access does not expire.
  final DateTime? expiresAt;

  /// False once the customer has cancelled: Pro then ends at [expiresAt].
  final bool willRenew;
  final bool inTrial;

  /// The store could not take the latest payment and is retrying.
  final bool hasBillingIssue;
  final SubscriptionStore store;

  /// The store's own page for changing or cancelling the subscription.
  final Uri? managementUrl;

  /// When the store confirmed all of the above.
  final DateTime? checkedAt;

  /// How long Pro stays on past [expiresAt] when a renewal was due but the
  /// store could not be asked, so a driver without signal does not lose Pro
  /// in the middle of a shift.
  static const renewalGrace = Duration(days: 3);

  /// Whether Pro is on at [now], judged from the last confirmed state alone
  /// so it works offline.
  ///
  /// Pro is certain until the paid period ends, or until the last moment
  /// the store itself said it was on if that is later. Past that point a
  /// cancelled subscription is over, and one that was due to renew gets
  /// [renewalGrace] for the store to be reached. An answer of "not active"
  /// from the store ends Pro whatever the dates say.
  bool isPremiumAt(DateTime now) {
    if (!entitled) return false;
    final end = expiresAt;
    if (end == null) return true;
    final checked = checkedAt;
    final certainUntil = checked != null && checked.isAfter(end)
        ? checked
        : end;
    if (now.isBefore(certainUntil)) return true;
    return willRenew && now.isBefore(certainUntil.add(renewalGrace));
  }

  Map<String, dynamic> toJson() => {
    'entitled': entitled,
    'period': period?.name,
    'expiresAt': expiresAt?.toUtc().toIso8601String(),
    'willRenew': willRenew,
    'inTrial': inTrial,
    'hasBillingIssue': hasBillingIssue,
    'store': store.name,
    'managementUrl': managementUrl?.toString(),
    'checkedAt': checkedAt?.toUtc().toIso8601String(),
  };

  /// Returns [none] for anything that is not a well-formed saved state, so a
  /// damaged record can never grant Pro.
  static SubscriptionState fromJson(Object? json) {
    if (json is! Map || json['entitled'] is! bool) return none;
    DateTime? date(Object? value) =>
        value is String ? DateTime.tryParse(value)?.toLocal() : null;
    // Null means lifetime access, so a missing or damaged expiry must not
    // silently turn a time-limited subscription into lifetime Pro.
    for (final field in ['expiresAt', 'checkedAt']) {
      if (!json.containsKey(field) ||
          (json[field] != null && date(json[field]) == null)) {
        return none;
      }
    }
    for (final field in ['willRenew', 'inTrial', 'hasBillingIssue']) {
      if (json[field] is! bool) return none;
    }
    if (json['entitled'] == true && date(json['checkedAt']) == null) {
      return none;
    }
    T? named<T extends Enum>(List<T> values, Object? name) {
      for (final value in values) {
        if (value.name == name) return value;
      }
      return null;
    }

    final url = json['managementUrl'];
    return SubscriptionState(
      entitled: json['entitled'] as bool,
      period: named(PlanPeriod.values, json['period']),
      expiresAt: date(json['expiresAt']),
      willRenew: json['willRenew'] == true,
      inTrial: json['inTrial'] == true,
      hasBillingIssue: json['hasBillingIssue'] == true,
      store:
          named(SubscriptionStore.values, json['store']) ??
          SubscriptionStore.other,
      managementUrl: url is String ? Uri.tryParse(url) : null,
      checkedAt: date(json['checkedAt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SubscriptionState &&
      other.entitled == entitled &&
      other.period == period &&
      other.expiresAt == expiresAt &&
      other.willRenew == willRenew &&
      other.inTrial == inTrial &&
      other.hasBillingIssue == hasBillingIssue &&
      other.store == store &&
      other.managementUrl == managementUrl &&
      other.checkedAt == checkedAt;

  @override
  int get hashCode => Object.hash(
    entitled,
    period,
    expiresAt,
    willRenew,
    inTrial,
    hasBillingIssue,
    store,
    managementUrl,
    checkedAt,
  );
}

/// Why a purchase or restore did not finish.
enum PurchaseFailureKind {
  /// The customer closed the store's payment sheet. Not an error to show.
  cancelled,

  /// Waiting on something outside the app: a parent's approval, or a slow
  /// payment method. Pro turns on by itself when the store confirms it.
  pending,
  network,

  /// Purchases are switched off on this device or for this account.
  notAllowed,

  /// The store account already has this subscription.
  alreadyOwned,
  store,
  unknown,
}

class PurchaseFailure implements Exception {
  const PurchaseFailure(this.kind, [this.detail]);

  final PurchaseFailureKind kind;

  /// Technical detail for logs; never shown to the customer.
  final String? detail;

  @override
  String toString() => 'PurchaseFailure(${kind.name}, $detail)';
}
