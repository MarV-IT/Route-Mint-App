import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../location/geolocator_tracking_provider.dart';
import '../storage/account_data_store.dart';

/// Publishes an account only after its local storage and tracking are ready.
class AccountSessionService extends ChangeNotifier {
  AccountSessionService({
    required FirebaseAuth auth,
    Future<void> Function()? beforeSwitch,
    VoidCallback? afterSwitch,
  }) : _auth = auth,
       _beforeSwitch = beforeSwitch ?? prepareTrackingForAccountChange,
       _afterSwitch = afterSwitch ?? completeTrackingAccountChange {
    _subscription = _auth.authStateChanges().listen(_onAuthChanged);
  }

  static AccountSessionService? _instance;
  static AccountSessionService get instance =>
      _instance ??= AccountSessionService(auth: FirebaseAuth.instance);

  final FirebaseAuth _auth;
  final Future<void> Function() _beforeSwitch;
  final VoidCallback _afterSwitch;
  final _changes = StreamController<User?>.broadcast();
  final _firstReady = Completer<void>();
  late final StreamSubscription<User?> _subscription;
  Future<void> _pending = Future.value();
  User? _user;
  String? _requestedUid;
  bool _initialized = false;
  bool _switching = true;
  bool _disposed = false;
  Object? _error;
  int _revision = 0;

  User? get user => isReady ? _user : null;
  bool get isReady => _initialized && !_switching && _error == null;
  bool get isSwitching => _switching;
  Object? get error => _error;
  int get revision => _revision;
  Stream<User?> get changes => _changes.stream;

  void _onAuthChanged(User? user) => _switchTo(user);

  void _switchTo(User? user, {bool force = false}) {
    if (_disposed) return;
    if (!force &&
        _revision > 0 &&
        _requestedUid == user?.uid &&
        (_switching || isReady)) {
      return;
    }
    _requestedUid = user?.uid;
    final revision = ++_revision;
    _switching = true;
    _error = null;
    notifyListeners();
    _pending = _pending.then((_) async {
      if (_disposed || revision != _revision) return;
      try {
        await _beforeSwitch();
        if (_disposed || revision != _revision) return;
        await AccountDataStore.activate(
          user?.uid,
          claimLegacy: !_initialized && user != null,
        );
        if (_disposed || revision != _revision) return;
        _user = user;
        _initialized = true;
        _switching = false;
        _changes.add(user);
      } catch (error) {
        if (revision == _revision) {
          _error = error;
          _switching = false;
        }
      } finally {
        _afterSwitch();
        if (!_disposed && revision == _revision) {
          if (!_firstReady.isCompleted) _firstReady.complete();
          notifyListeners();
        }
      }
    });
  }

  Future<void> initialize() async {
    await _firstReady.future;
    if (_error != null) throw StateError('Account storage could not be opened');
  }

  /// Covers platforms where the sign-in result arrives before its auth event.
  Future<void> synchronize() async {
    _switchTo(_auth.currentUser);
    while (_switching) {
      await _pending;
    }
    if (_error != null) throw StateError('Account storage could not be opened');
  }

  Future<void> retry() async {
    _switchTo(_auth.currentUser, force: true);
    await _pending;
    if (_error != null) throw StateError('Account storage could not be opened');
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    unawaited(_changes.close());
    super.dispose();
  }
}
