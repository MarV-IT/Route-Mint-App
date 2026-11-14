import 'subscription_models.dart';

/// The app's only door to a store. Everything behind it — RevenueCat, the
/// App Store, Google Play, product identifiers — stays out of the rest of
/// the code, which only ever asks whether Pro is on.
///
/// Calls fail with [PurchaseFailure].
abstract interface class PurchaseGateway {
  /// Connects to the store for [appUserId], or for an anonymous customer
  /// when it is null. Called once, before anything else.
  Future<void> start(String? appUserId);

  /// Follows the app's account: a signed-in account keeps its subscription
  /// across devices and platforms, null goes back to an anonymous customer.
  Future<void> switchUser(String? appUserId);

  /// What the store knows now. Offline, the store SDK answers from what it
  /// last heard, with the original time in [SubscriptionState.checkedAt].
  Future<SubscriptionState> currentState();

  /// Changes the app did not ask for: a renewal, a refund, a pending
  /// purchase being approved.
  Stream<SubscriptionState> get updates;

  /// The plans on sale to this customer, with their own prices and trial.
  Future<List<SubscriptionPlan>> plans();

  Future<SubscriptionState> purchase(SubscriptionPlan plan);

  /// Finds purchases made earlier with the same store account, for a new
  /// phone or a reinstall.
  Future<SubscriptionState> restore();
}
