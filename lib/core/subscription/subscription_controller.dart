import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../preferences/user_preferences.dart';
import '../storage/account_data_store.dart';
import 'purchase_gateway.dart';
import 'revenuecat_gateway.dart';
import 'subscription_config.dart';
import 'subscription_models.dart';

/// The one place that knows whether Pro is on.
///
/// It follows the app's account, asks the store at start and whenever the
/// app comes back to the foreground, and keeps the last confirmed answer
/// per account on the device so Pro neither flickers at launch nor drops
/// while offline. Listeners are told whenever [isPremium] or [state] change.
class SubscriptionController extends ChangeNotifier {
  SubscriptionController({
    PurchaseGateway? gateway,
    DateTime Function()? clock,
    this.isTestStore = false,
  }) : _gateway = gateway,
       _clock = clock ?? DateTime.now;

  /// Uses RevenueCat when this build has a key for the platform, and no
  /// store at all otherwise.
  factory SubscriptionController.fromConfig() => SubscriptionController(
    isTestStore: SubscriptionConfig.isTestStore,
    gateway: SubscriptionConfig.storeEnabled
        ? RevenueCatGateway(
            apiKey: SubscriptionConfig.apiKey,
            entitlementId: SubscriptionConfig.entitlementId,
          )
        : null,
  );

  /// Kept apart from user preferences on purpose: preferences travel in
  /// backups, and a backup must never carry Pro to another device.
  static const snapshotKey = 'subscription_snapshot';

  final PurchaseGateway? _gateway;
  final DateTime Function() _clock;
  final bool isTestStore;

  SubscriptionState _state = SubscriptionState.none;
  AccountDataScope? _scope;
  AccountDataScope? _connectedScope;
  StreamSubscription<SubscriptionState>? _updates;
  Future<void>? _queue;
  int _generation = 0;
  bool _started = false;
  bool _lastPremium = false;
  bool _disposed = false;
  bool _handlingStoreCall = false;
  bool _updateRefreshPending = false;

  /// False until the store is switched on for this build; the app then
  /// behaves as it did before subscriptions.
  bool get storeEnabled => _gateway != null;

  SubscriptionState get state => _state;

  bool get isPremium => _state.isPremiumAt(_clock());

  /// The subscription status the rest of the app should work with, given
  /// what is [stored] in preferences.
  ///
  /// With the store on, only the store grants Pro; a stored value is at most
  /// a copy of its last answer. The tester switch keeps working in debug
  /// builds so Pro screens can be developed without buying anything.
  SubscriptionStatus statusFor(SubscriptionStatus stored) {
    if (!storeEnabled) return stored;
    if (isPremium) return SubscriptionStatus.pro;
    if (kDebugMode && stored == SubscriptionStatus.testerPro) return stored;
    return SubscriptionStatus.free;
  }

  UserPreferences applyTo(UserPreferences preferences) {
    final status = statusFor(preferences.subscriptionStatus);
    return status == preferences.subscriptionStatus
        ? preferences
        : preferences.copyWith(subscriptionStatus: status);
  }

  /// Switches to the account that just became active: brings back what the
  /// store last confirmed for it, then reconnects in the background.
  Future<void> attach(AccountDataScope scope) async {
    final gateway = _gateway;
    if (gateway == null) return;
    final generation = ++_generation;
    _scope = scope;
    _setState(SubscriptionState.none);
    final saved = await _load(scope);
    if (generation != _generation || _disposed) return;
    _setState(saved);
    // Needs the network, which a cold start must never wait for.
    unawaited(_enqueue(() => _connectAndRefresh(scope, generation)));
  }

  /// Asks the store again. Called when the app returns to the foreground,
  /// where a renewal, a cancellation or a refund may have happened since.
  Future<void> refresh() {
    final scope = _scope;
    if (_gateway == null || scope == null) return Future<void>.value();
    final generation = _generation;
    return _enqueue(() => _connectAndRefresh(scope, generation));
  }

  Future<List<SubscriptionPlan>> loadPlans() =>
      _forCurrentAccount((gateway) => gateway.plans());

  /// Buys [plan]. Completes normally only when the store has taken the
  /// purchase; Pro is then already on.
  Future<void> purchase(SubscriptionPlan plan) => _forCurrentAccount(
    (gateway) => gateway.purchase(plan),
    accept: true,
  ).then((_) {});

  /// Returns whether an earlier purchase was found and Pro is now on.
  Future<bool> restore() => _forCurrentAccount(
    (gateway) => gateway.restore(),
    accept: true,
  ).then((state) => state.isPremiumAt(_clock()));

  PurchaseGateway _requireGateway() =>
      _gateway ??
      (throw const PurchaseFailure(
        PurchaseFailureKind.store,
        'purchases are not switched on in this build',
      ));

  Future<T> _forCurrentAccount<T>(
    Future<T> Function(PurchaseGateway gateway) action, {
    bool accept = false,
  }) async {
    final gateway = _requireGateway();
    final scope = _scope ?? AccountDataStore.current;
    _scope = scope;
    final generation = _generation;
    return _enqueue(() async {
      _checkAccount(scope, generation);
      await _connect(scope, generation, rethrowFailure: true);
      // An account may change while the native SDK is connecting.
      _checkAccount(scope, generation);
      _handlingStoreCall = true;
      try {
        final result = await action(gateway);
        _checkAccount(scope, generation);
        if (accept) await _accept(result as SubscriptionState);
        _checkAccount(scope, generation);
        return result;
      } finally {
        _handlingStoreCall = false;
      }
    });
  }

  void _checkAccount(AccountDataScope scope, int generation) {
    if (_disposed || generation != _generation || !identical(scope, _scope)) {
      throw const PurchaseFailure(
        PurchaseFailureKind.cancelled,
        'the account changed before this operation completed',
      );
    }
  }

  Future<void> _connectAndRefresh(
    AccountDataScope scope,
    int generation,
  ) async {
    await _connect(scope, generation);
    if (_disposed ||
        generation != _generation ||
        !identical(_connectedScope, scope)) {
      // Still on the previous customer, so its answer is not this account's.
      _notifyIfPremiumChanged();
      return;
    }
    _handlingStoreCall = true;
    try {
      final fresh = await _gateway!.currentState();
      if (generation == _generation) await _accept(fresh);
    } on PurchaseFailure catch (failure) {
      _log('refresh skipped: $failure');
    } finally {
      _handlingStoreCall = false;
    }
    // Even without an answer time has passed, and a period may have ended.
    _notifyIfPremiumChanged();
  }

  Future<void> _connect(
    AccountDataScope scope,
    int generation, {
    bool rethrowFailure = false,
  }) async {
    final gateway = _gateway!;
    if (_disposed ||
        generation != _generation ||
        identical(_connectedScope, scope)) {
      return;
    }
    _handlingStoreCall = true;
    try {
      if (_started) {
        await gateway.switchUser(scope.uid);
      } else {
        await gateway.start(scope.uid);
        _started = true;
        _updates = gateway.updates.listen(_onStoreUpdate);
      }
      _connectedScope = scope;
    } on PurchaseFailure catch (failure) {
      _log('connect failed: $failure');
      if (rethrowFailure) rethrow;
    } finally {
      _handlingStoreCall = false;
    }
  }

  void _onStoreUpdate(SubscriptionState update) {
    // Listener payloads have no reliable app-account identity. A delayed
    // event from the old customer only asks us to re-read the current one.
    // Explicit SDK calls consume their own result and may emit events too.
    if (_disposed ||
        _handlingStoreCall ||
        _updateRefreshPending ||
        !identical(_connectedScope, _scope)) {
      return;
    }
    _updateRefreshPending = true;
    unawaited(refresh().whenComplete(() => _updateRefreshPending = false));
  }

  Future<void> _accept(SubscriptionState next) async {
    final scope = _scope;
    if (_disposed || scope == null) return;
    _setState(next);
    try {
      final preferences = await scope.getPreferences();
      await preferences.setString(snapshotKey, jsonEncode(next.toJson()));
    } catch (error) {
      _log('could not save the confirmed state: $error');
    }
  }

  void _setState(SubscriptionState next) {
    final changed = next != _state;
    _state = next;
    final premium = isPremium;
    if (changed || premium != _lastPremium) {
      _lastPremium = premium;
      notifyListeners();
    }
  }

  void _notifyIfPremiumChanged() {
    if (_disposed) return;
    final premium = isPremium;
    if (premium == _lastPremium) return;
    _lastPremium = premium;
    notifyListeners();
  }

  Future<SubscriptionState> _load(AccountDataScope scope) async {
    try {
      final preferences = await scope.getPreferences();
      final raw = preferences.getString(snapshotKey);
      if (raw == null) return SubscriptionState.none;
      return SubscriptionState.fromJson(jsonDecode(raw));
    } catch (_) {
      return SubscriptionState.none;
    }
  }

  /// Customer switches and all customer-bound store calls run one at a time.
  Future<T> _enqueue<T>(Future<T> Function() task) {
    final previous = _queue;
    final next = previous == null
        ? Future<T>.sync(task)
        : previous.then((_) => task());
    final tail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _queue = tail;
    unawaited(
      tail.then((_) {
        if (identical(_queue, tail)) _queue = null;
      }),
    );
    return next;
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[Subscription] $message');
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_updates?.cancel());
    super.dispose();
  }
}

SubscriptionController? _appSubscription;

/// The app-wide subscription state.
SubscriptionController get appSubscription =>
    _appSubscription ??= SubscriptionController.fromConfig();

@visibleForTesting
set appSubscription(SubscriptionController? controller) =>
    _appSubscription = controller;
