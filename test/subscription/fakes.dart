import 'dart:async';

import 'package:route_mint_app/core/subscription/purchase_gateway.dart';
import 'package:route_mint_app/core/subscription/subscription_models.dart';

/// A store that answers from memory, one customer record per account.
class FakeGateway implements PurchaseGateway {
  final _updates = StreamController<SubscriptionState>.broadcast(sync: true);

  /// What the "store" knows about each customer; null is the anonymous one.
  final byUser = <String?, SubscriptionState>{};

  /// Every call in order, e.g. `start:A`, `switch:null`, `state`.
  final calls = <String>[];

  String? user;
  bool started = false;

  PurchaseFailure? connectFailure;
  PurchaseFailure? stateFailure;
  PurchaseFailure? plansFailure;
  PurchaseFailure? purchaseFailure;
  PurchaseFailure? restoreFailure;

  List<SubscriptionPlan> offered = const [annualPlan, monthlyPlan];

  /// What the store reports after a successful purchase or restore.
  SubscriptionState purchased = activeAnnual;
  SubscriptionState restored = SubscriptionState.none;

  /// Lets a test hold a purchase open, as the payment sheet does.
  Completer<void>? purchaseGate;
  Completer<void>? connectGate;
  Completer<void>? restoreGate;
  bool emitOnStateRead = false;

  void pushStale(SubscriptionState state) => _updates.add(state);

  @override
  Stream<SubscriptionState> get updates => _updates.stream;

  /// A change the app did not ask for: a renewal, a refund.
  void push(SubscriptionState state) {
    byUser[user] = state;
    _updates.add(state);
  }

  @override
  Future<void> start(String? appUserId) async {
    calls.add('start:$appUserId');
    await connectGate?.future;
    if (connectFailure != null) throw connectFailure!;
    started = true;
    user = appUserId;
  }

  @override
  Future<void> switchUser(String? appUserId) async {
    calls.add('switch:$appUserId');
    await connectGate?.future;
    if (connectFailure != null) throw connectFailure!;
    user = appUserId;
  }

  @override
  Future<SubscriptionState> currentState() async {
    calls.add('state');
    if (stateFailure != null) throw stateFailure!;
    if (emitOnStateRead) _updates.add(byUser[user] ?? SubscriptionState.none);
    return byUser[user] ?? SubscriptionState.none;
  }

  @override
  Future<List<SubscriptionPlan>> plans() async {
    calls.add('plans');
    if (plansFailure != null) throw plansFailure!;
    return List.of(offered);
  }

  @override
  Future<SubscriptionState> purchase(SubscriptionPlan plan) async {
    calls.add('purchase:${plan.id}');
    await purchaseGate?.future;
    if (purchaseFailure != null) throw purchaseFailure!;
    return byUser[user] = purchased;
  }

  @override
  Future<SubscriptionState> restore() async {
    calls.add('restore');
    await restoreGate?.future;
    if (restoreFailure != null) throw restoreFailure!;
    return byUser[user] = restored;
  }

  Future<void> close() => _updates.close();
}

/// The moment the fixtures below were "confirmed by the store".
final checkedAt = DateTime(2026, 11, 12, 10);

const annualPlan = SubscriptionPlan(
  id: r'$rc_annual',
  period: PlanPeriod.annual,
  priceText: r'$39.99',
  price: 39.99,
  currencyCode: 'USD',
  monthlyPriceText: r'$3.33',
  trial: FreeTrial(7, TrialUnit.day),
);

const monthlyPlan = SubscriptionPlan(
  id: r'$rc_monthly',
  period: PlanPeriod.monthly,
  priceText: r'$4.99',
  price: 4.99,
  currencyCode: 'USD',
);

/// Paid for a year from [checkedAt] and set to renew.
final activeAnnual = SubscriptionState(
  entitled: true,
  period: PlanPeriod.annual,
  expiresAt: DateTime(2027, 11, 12, 10),
  willRenew: true,
  store: SubscriptionStore.playStore,
  checkedAt: checkedAt,
);

SubscriptionState stateWith({
  bool entitled = true,
  PlanPeriod? period = PlanPeriod.monthly,
  DateTime? expiresAt,
  bool willRenew = true,
  bool inTrial = false,
  bool hasBillingIssue = false,
  SubscriptionStore store = SubscriptionStore.playStore,
  Uri? managementUrl,
  DateTime? checked,
}) => SubscriptionState(
  entitled: entitled,
  period: period,
  expiresAt: expiresAt,
  willRenew: willRenew,
  inTrial: inTrial,
  hasBillingIssue: hasBillingIssue,
  store: store,
  managementUrl: managementUrl,
  checkedAt: checked ?? checkedAt,
);
