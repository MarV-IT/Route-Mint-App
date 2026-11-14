import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:route_mint_app/core/subscription/revenuecat_gateway.dart';
import 'package:route_mint_app/core/subscription/subscription_models.dart';

const _asked = '2026-11-12T10:00:00Z';

EntitlementInfo entitlement({
  bool isActive = true,
  bool willRenew = true,
  String product = 'marvroute_pro_annual',
  String? basePlan,
  Store store = Store.playStore,
  PeriodType periodType = PeriodType.normal,
  String? expires = '2027-11-12T10:00:00Z',
  String? billingIssue,
}) => EntitlementInfo(
  'pro',
  isActive,
  willRenew,
  '2026-11-12T09:00:00Z',
  '2026-11-12T09:00:00Z',
  product,
  true,
  store: store,
  periodType: periodType,
  expirationDate: expires,
  billingIssueDetectedAt: billingIssue,
  productPlanIdentifier: basePlan,
);

CustomerInfo customer({
  EntitlementInfo? pro,
  String requestDate = _asked,
  String? managementURL,
  String entitlementId = 'pro',
}) => CustomerInfo(
  EntitlementInfos(
    {entitlementId: ?pro},
    {if (pro != null && pro.isActive) entitlementId: pro},
  ),
  const {},
  const [],
  const [],
  const [],
  '2026-01-01T00:00:00Z',
  'user',
  const {},
  requestDate,
  managementURL: managementURL,
);

SubscriptionState stateOf(CustomerInfo info) =>
    stateFromCustomerInfo(info, entitlementId: 'pro');

const _context = PresentedOfferingContext('default', null, null);

Package package({
  PackageType type = PackageType.annual,
  String id = r'$rc_annual',
  String product = 'marvroute_pro_annual',
  double price = 39.99,
  String priceText = r'$39.99',
  String? period = 'P1Y',
  String? perMonth = r'$3.33',
  IntroductoryPrice? intro,
  SubscriptionOption? option,
}) => Package(
  id,
  type,
  StoreProduct(
    product,
    'All Pro features',
    'MarV Route Pro',
    price,
    priceText,
    'USD',
    introductoryPrice: intro,
    defaultOption: option,
    subscriptionPeriod: period,
    pricePerMonthString: perMonth,
  ),
  _context,
);

/// A Google Play base plan, optionally with a free first phase.
SubscriptionOption playOption({Period? free}) {
  const year = Period(PeriodUnit.year, 1, 'P1Y');
  const full = PricingPhase(
    year,
    RecurrenceMode.infiniteRecurring,
    null,
    Price(r'$39.99', 39990000, 'USD'),
    null,
  );
  final freePhase = free == null
      ? null
      : PricingPhase(
          free,
          RecurrenceMode.finiteRecurring,
          1,
          const Price('Free', 0, 'USD'),
          OfferPaymentMode.freeTrial,
        );
  return SubscriptionOption(
    'annual',
    'marvroute_pro:annual',
    'marvroute_pro',
    [?freePhase, full],
    const [],
    free == null,
    year,
    false,
    full,
    freePhase,
    null,
    _context,
    null,
  );
}

void main() {
  group('customer record', () {
    test('an active yearly subscription', () {
      final state = stateOf(
        customer(
          pro: entitlement(),
          managementURL: 'https://play.google.com/store/account/subscriptions',
        ),
      );

      expect(state.entitled, isTrue);
      expect(state.period, PlanPeriod.annual);
      expect(state.expiresAt, DateTime.utc(2027, 11, 12, 10).toLocal());
      expect(state.willRenew, isTrue);
      expect(state.inTrial, isFalse);
      expect(state.hasBillingIssue, isFalse);
      expect(state.store, SubscriptionStore.playStore);
      expect(state.managementUrl?.host, 'play.google.com');
      expect(state.checkedAt, DateTime.utc(2026, 11, 12, 10).toLocal());
      expect(state.isPremiumAt(DateTime.utc(2026, 12)), isTrue);
    });

    test('someone who never bought anything', () {
      final state = stateOf(customer());
      expect(state.entitled, isFalse);
      expect(state.isPremiumAt(DateTime.utc(2026, 12)), isFalse);
      // Still records that the store was asked.
      expect(state.checkedAt, isNotNull);
    });

    test('another entitlement does not unlock Pro', () {
      final state = stateOf(
        customer(pro: entitlement(), entitlementId: 'something_else'),
      );
      expect(state.entitled, isFalse);
    });

    test('a cancelled subscription keeps its paid time', () {
      final state = stateOf(customer(pro: entitlement(willRenew: false)));
      expect(state.entitled, isTrue);
      expect(state.willRenew, isFalse);
      expect(state.isPremiumAt(DateTime.utc(2027, 11, 12, 9)), isTrue);
      expect(state.isPremiumAt(DateTime.utc(2027, 11, 12, 11)), isFalse);
    });

    test('an expired or refunded subscription is off', () {
      final state = stateOf(
        customer(
          pro: entitlement(
            isActive: false,
            willRenew: false,
            expires: '2026-11-01T10:00:00Z',
          ),
        ),
      );
      expect(state.entitled, isFalse);
      expect(state.isPremiumAt(DateTime.utc(2026, 11, 12, 11)), isFalse);
    });

    test('a trial, a billing problem and the App Store are recognised', () {
      final state = stateOf(
        customer(
          pro: entitlement(
            periodType: PeriodType.trial,
            store: Store.appStore,
            billingIssue: '2026-11-11T10:00:00Z',
            product: 'marvroute_pro_monthly',
          ),
        ),
      );
      expect(state.inTrial, isTrue);
      expect(state.hasBillingIssue, isTrue);
      expect(state.store, SubscriptionStore.appStore);
      expect(state.period, PlanPeriod.monthly);
    });

    test('a Google Play base plan names the period', () {
      final state = stateOf(
        customer(
          pro: entitlement(product: 'marvroute_pro', basePlan: 'monthly'),
        ),
      );
      expect(state.period, PlanPeriod.monthly);
    });

    test('a grant with no end date and no store', () {
      final state = stateOf(
        customer(
          pro: entitlement(
            expires: null,
            store: Store.promotional,
            product: 'rc_promo_pro_lifetime',
          ),
        ),
      );
      expect(state.entitled, isTrue);
      expect(state.expiresAt, isNull);
      expect(state.store, SubscriptionStore.other);
      expect(state.isPremiumAt(DateTime.utc(2040)), isTrue);
    });

    test('an old cached answer still counts as of when it was given', () {
      // Offline for days: the SDK re-judges its cached record against the
      // device clock and flags it inactive, but it was active when the
      // store answered, and the renewal grace is decided by the app.
      final state = stateOf(
        customer(
          pro: entitlement(isActive: false, expires: '2026-11-13T10:00:00Z'),
        ),
      );
      expect(state.entitled, isTrue);
      expect(state.isPremiumAt(DateTime.utc(2026, 11, 14, 10)), isTrue);
      expect(state.isPremiumAt(DateTime.utc(2026, 11, 17, 10)), isFalse);
    });
  });

  group('plans', () {
    test('a yearly plan with its store price and per-month figure', () {
      final plan = planFromPackage(package(), appStoreTrialEligible: false)!;
      expect(plan.id, r'$rc_annual');
      expect(plan.period, PlanPeriod.annual);
      expect(plan.priceText, r'$39.99');
      expect(plan.price, 39.99);
      expect(plan.currencyCode, 'USD');
      expect(plan.monthlyPriceText, r'$3.33');
      expect(plan.trial, isNull);
    });

    test('a monthly plan has no per-month line of its own', () {
      final plan = planFromPackage(
        package(
          type: PackageType.monthly,
          id: r'$rc_monthly',
          price: 4.99,
          priceText: r'$4.99',
          period: 'P1M',
          perMonth: r'$4.99',
        ),
        appStoreTrialEligible: false,
      )!;
      expect(plan.period, PlanPeriod.monthly);
      expect(plan.monthlyPriceText, isNull);
    });

    test('a custom package is placed by its billing period', () {
      final plan = planFromPackage(
        package(type: PackageType.custom, id: 'yearly_promo'),
        appStoreTrialEligible: false,
      )!;
      expect(plan.period, PlanPeriod.annual);
    });

    test('anything that is not monthly or yearly is left off the paywall', () {
      for (final type in [PackageType.lifetime, PackageType.weekly]) {
        expect(
          planFromPackage(
            package(
              type: type,
              period: type == PackageType.weekly ? 'P1W' : null,
            ),
            appStoreTrialEligible: true,
          ),
          isNull,
          reason: '$type',
        );
      }
    });

    test('Google Play: a free first phase is the trial', () {
      final plan = planFromPackage(
        package(
          option: playOption(free: const Period(PeriodUnit.day, 7, 'P7D')),
        ),
        appStoreTrialEligible: false,
      )!;
      expect(plan.trial, const FreeTrial(7, TrialUnit.day));
    });

    test('Google Play: no free phase, no trial', () {
      final plan = planFromPackage(
        package(option: playOption()),
        appStoreTrialEligible: true,
      )!;
      expect(plan.trial, isNull);
    });

    test('App Store: the trial shows only to someone who can still get it', () {
      const intro = IntroductoryPrice(0, 'Free', 'P1W', 1, PeriodUnit.week, 1);
      expect(
        planFromPackage(
          package(intro: intro),
          appStoreTrialEligible: true,
        )!.trial,
        const FreeTrial(1, TrialUnit.week),
      );
      expect(
        planFromPackage(
          package(intro: intro),
          appStoreTrialEligible: false,
        )!.trial,
        isNull,
      );
    });

    test('App Store: a discounted first period is not called free', () {
      const intro = IntroductoryPrice(
        0.99,
        r'$0.99',
        'P1M',
        1,
        PeriodUnit.month,
        1,
      );
      expect(
        planFromPackage(
          package(intro: intro),
          appStoreTrialEligible: true,
        )!.trial,
        isNull,
      );
    });
  });

  group('store errors', () {
    PurchaseFailureKind kindOf(PurchasesErrorCode code) =>
        failureFromPlatformException(
          PlatformException(code: '${code.index}', message: 'details'),
        ).kind;

    test('closing the payment sheet is a cancellation', () {
      expect(
        kindOf(PurchasesErrorCode.purchaseCancelledError),
        PurchaseFailureKind.cancelled,
      );
    });

    test('ask-to-buy and slow payments are pending, not failed', () {
      expect(
        kindOf(PurchasesErrorCode.paymentPendingError),
        PurchaseFailureKind.pending,
      );
    });

    test('connection problems are told apart from store problems', () {
      for (final code in [
        PurchasesErrorCode.networkError,
        PurchasesErrorCode.offlineConnectionError,
        PurchasesErrorCode.productRequestTimeout,
      ]) {
        expect(kindOf(code), PurchaseFailureKind.network, reason: code.name);
      }
      expect(
        kindOf(PurchasesErrorCode.storeProblemError),
        PurchaseFailureKind.store,
      );
      expect(
        kindOf(PurchasesErrorCode.purchaseNotAllowedError),
        PurchaseFailureKind.notAllowed,
      );
      expect(
        kindOf(PurchasesErrorCode.productAlreadyPurchasedError),
        PurchaseFailureKind.alreadyOwned,
      );
    });

    test('codes the SDK does not explain never crash the app', () {
      for (final code in ['not-a-number', '9999', '']) {
        expect(
          failureFromPlatformException(PlatformException(code: code)).kind,
          PurchaseFailureKind.unknown,
          reason: code,
        );
      }
    });
  });
}
