import 'dart:async';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'purchase_gateway.dart';
import 'subscription_models.dart';

/// Sells Pro through RevenueCat, which talks to the App Store and Google
/// Play, checks receipts on its servers and keeps one customer record per
/// app account across both platforms.
class RevenueCatGateway implements PurchaseGateway {
  RevenueCatGateway({required this.apiKey, required this.entitlementId});

  final String apiKey;
  final String entitlementId;

  final _updates = StreamController<SubscriptionState>.broadcast();

  /// Packages of the last offering shown, by plan id, so a purchase buys
  /// exactly what the customer was looking at.
  final _packages = <String, Package>{};
  final _periodByProduct = <String, PlanPeriod>{};

  @override
  Stream<SubscriptionState> get updates => _updates.stream;

  @override
  Future<void> start(String? appUserId) => _guard(() async {
    if (await Purchases.isConfigured) {
      await _switchUser(appUserId);
    } else {
      final configuration = PurchasesConfiguration(apiKey)
        ..appUserID = appUserId
        // Purchases need no advertising or device identifiers.
        ..automaticDeviceIdentifierCollectionEnabled = false;
      await Purchases.configure(configuration);
    }
    Purchases.addCustomerInfoUpdateListener(
      (info) => _updates.add(_state(info)),
    );
  });

  @override
  Future<void> switchUser(String? appUserId) =>
      _guard(() => _switchUser(appUserId));

  Future<void> _switchUser(String? appUserId) async {
    if (appUserId != null) {
      await Purchases.logIn(appUserId);
    } else if (!await Purchases.isAnonymous) {
      await Purchases.logOut();
    }
  }

  @override
  Future<SubscriptionState> currentState() =>
      _guard(() async => _state(await Purchases.getCustomerInfo()));

  @override
  Future<List<SubscriptionPlan>> plans() => _guard(() async {
    final offerings = await Purchases.getOfferings();
    final packages = offerings.current?.availablePackages ?? const <Package>[];

    // The App Store does not say by itself whether this customer has used
    // the trial; Google Play only lists offers the customer can still get.
    final appStoreTrials = [
      for (final package in packages)
        if (package.storeProduct.defaultOption == null &&
            package.storeProduct.introductoryPrice?.price == 0)
          package.storeProduct.identifier,
    ];
    var eligible = const <String>{};
    if (appStoreTrials.isNotEmpty) {
      try {
        final answers =
            await Purchases.checkTrialOrIntroductoryPriceEligibility(
              appStoreTrials,
            );
        eligible = {
          for (final entry in answers.entries)
            if (entry.value.status ==
                IntroEligibilityStatus.introEligibilityStatusEligible)
              entry.key,
        };
      } catch (_) {
        // Unknown: promise no trial rather than one the store may not give.
      }
    }

    _packages.clear();
    final plans = <SubscriptionPlan>[];
    for (final package in packages) {
      final plan = planFromPackage(
        package,
        appStoreTrialEligible: eligible.contains(
          package.storeProduct.identifier,
        ),
      );
      if (plan == null) continue;
      _packages[plan.id] = package;
      _periodByProduct[package.storeProduct.identifier] = plan.period;
      plans.add(plan);
    }
    return plans;
  });

  @override
  Future<SubscriptionState> purchase(SubscriptionPlan plan) => _guard(() async {
    final package = _packages[plan.id];
    if (package == null) {
      throw const PurchaseFailure(
        PurchaseFailureKind.store,
        'plan is no longer on offer',
      );
    }
    final result = await Purchases.purchase(PurchaseParams.package(package));
    return _state(result.customerInfo);
  });

  @override
  Future<void> presentOfferCodeSheet() =>
      _guard(Purchases.presentCodeRedemptionSheet);

  @override
  Future<SubscriptionState> restore() =>
      _guard(() async => _state(await Purchases.restorePurchases()));

  SubscriptionState _state(CustomerInfo info) => stateFromCustomerInfo(
    info,
    entitlementId: entitlementId,
    periodByProduct: _periodByProduct,
  );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (error) {
      throw failureFromPlatformException(error);
    } on MissingPluginException catch (error) {
      throw PurchaseFailure(PurchaseFailureKind.store, '$error');
    }
  }
}

/// Reads the app's view of Pro out of RevenueCat's customer record.
SubscriptionState stateFromCustomerInfo(
  CustomerInfo info, {
  required String entitlementId,
  Map<String, PlanPeriod> periodByProduct = const {},
}) {
  final checkedAt = _date(info.requestDate);
  final managementUrl = info.managementURL == null
      ? null
      : Uri.tryParse(info.managementURL!);
  final entitlement = info.entitlements.all[entitlementId];
  if (entitlement == null) {
    return SubscriptionState(
      entitled: false,
      checkedAt: checkedAt,
      managementUrl: managementUrl,
    );
  }

  final expiresAt = _date(entitlement.expirationDate);
  // "Active" as of the moment RevenueCat answered. The SDK re-judges an old
  // cached answer against the device clock, so the dates are consulted too:
  // what happens after the answer is SubscriptionState.isPremiumAt's job.
  final activeByDates =
      expiresAt != null && checkedAt != null && expiresAt.isAfter(checkedAt);
  return SubscriptionState(
    entitled: entitlement.isActive || activeByDates,
    period:
        periodByProduct[entitlement.productIdentifier] ??
        _periodFromIdentifiers(
          entitlement.productIdentifier,
          entitlement.productPlanIdentifier,
        ),
    expiresAt: expiresAt,
    willRenew: entitlement.willRenew,
    inTrial: entitlement.periodType == PeriodType.trial,
    hasBillingIssue: entitlement.billingIssueDetectedAt != null,
    store: switch (entitlement.store) {
      Store.appStore || Store.macAppStore => SubscriptionStore.appStore,
      Store.playStore => SubscriptionStore.playStore,
      _ => SubscriptionStore.other,
    },
    managementUrl: managementUrl,
    checkedAt: checkedAt,
  );
}

/// Turns a RevenueCat package into a plan the paywall can show, or null for
/// packages the paywall has no honest wording for (anything that is not a
/// monthly or yearly subscription).
SubscriptionPlan? planFromPackage(
  Package package, {
  required bool appStoreTrialEligible,
}) {
  final product = package.storeProduct;
  final period = switch (package.packageType) {
    PackageType.monthly => PlanPeriod.monthly,
    PackageType.annual => PlanPeriod.annual,
    _ => switch (product.subscriptionPeriod) {
      'P1M' => PlanPeriod.monthly,
      'P1Y' => PlanPeriod.annual,
      _ => PlanPeriod.other,
    },
  };
  if (period == PlanPeriod.other) return null;

  FreeTrial? trial;
  final playOption = product.defaultOption;
  if (playOption != null) {
    final free = playOption.freePhase?.billingPeriod;
    if (free != null) trial = _trial(free.value, free.unit);
  } else if (appStoreTrialEligible) {
    final intro = product.introductoryPrice;
    if (intro != null && intro.price == 0) {
      trial = _trial(intro.periodNumberOfUnits, intro.periodUnit);
    }
  }

  return SubscriptionPlan(
    id: package.identifier,
    period: period,
    priceText: product.priceString,
    price: product.price,
    currencyCode: product.currencyCode,
    monthlyPriceText: period == PlanPeriod.annual
        ? product.pricePerMonthString
        : null,
    trial: trial,
  );
}

PurchaseFailure failureFromPlatformException(PlatformException error) {
  PurchasesErrorCode code;
  try {
    code = PurchasesErrorHelper.getErrorCode(error);
  } catch (_) {
    code = PurchasesErrorCode.unknownError;
  }
  final kind = switch (code) {
    PurchasesErrorCode.purchaseCancelledError => PurchaseFailureKind.cancelled,
    PurchasesErrorCode.paymentPendingError => PurchaseFailureKind.pending,
    PurchasesErrorCode.networkError ||
    PurchasesErrorCode.offlineConnectionError ||
    PurchasesErrorCode.productRequestTimeout ||
    PurchasesErrorCode.apiEndpointBlocked => PurchaseFailureKind.network,
    PurchasesErrorCode.purchaseNotAllowedError =>
      PurchaseFailureKind.notAllowed,
    PurchasesErrorCode.productAlreadyPurchasedError =>
      PurchaseFailureKind.alreadyOwned,
    PurchasesErrorCode.storeProblemError ||
    PurchasesErrorCode.productNotAvailableForPurchaseError ||
    PurchasesErrorCode.purchaseInvalidError => PurchaseFailureKind.store,
    _ => PurchaseFailureKind.unknown,
  };
  return PurchaseFailure(kind, '${code.name}: ${error.message}');
}

DateTime? _date(String? value) =>
    value == null ? null : DateTime.tryParse(value)?.toLocal();

FreeTrial? _trial(int count, PeriodUnit unit) {
  final trialUnit = switch (unit) {
    PeriodUnit.day => TrialUnit.day,
    PeriodUnit.week => TrialUnit.week,
    PeriodUnit.month => TrialUnit.month,
    PeriodUnit.year => TrialUnit.year,
    PeriodUnit.unknown => null,
  };
  return trialUnit == null || count <= 0 ? null : FreeTrial(count, trialUnit);
}

/// A fallback for naming the plan in Profile before the offering has been
/// loaded in this session. Follows the product names in SUBSCRIPTIONS.md.
PlanPeriod? _periodFromIdentifiers(String product, String? basePlan) {
  final id = '$product ${basePlan ?? ''}'.toLowerCase();
  if (id.contains('annual') || id.contains('year')) return PlanPeriod.annual;
  if (id.contains('month')) return PlanPeriod.monthly;
  return null;
}
