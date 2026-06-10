import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _sessionExpectedKey = 'firebase_auth_session_expected';
  static const _storedEmailKey = 'auth_email';
  static const _storedPasswordKey = 'auth_password';
  static const _secureStorage = FlutterSecureStorage();
  static User? _cachedUser;
  static Stream<User?>? _cachedAuthStateChanges;
  static bool _cacheListenerStarted = false;

  final _auth = FirebaseAuth.instance;

  AuthService() {
    _ensureCacheListener();
  }

  User? get currentUser => _auth.currentUser ?? _cachedUser;

  User? get rawCurrentUser => _auth.currentUser;

  User? get cachedUser => _cachedUser;

  Stream<User?> authStateChanges() {
    _cachedAuthStateChanges ??= _auth.authStateChanges().asBroadcastStream();
    return _cachedAuthStateChanges!;
  }

  void _ensureCacheListener() {
    if (_cacheListenerStarted) return;
    _cacheListenerStarted = true;
    _cachedUser = _auth.currentUser;
    authStateChanges().listen((user) async {
      if (user != null) {
        _cachedUser = user;
        await _setSessionExpected(true);
      }
    });
  }

  Future<bool> isSessionExpected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionExpectedKey) ?? false;
  }

  Future<void> _setSessionExpected(bool expected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionExpectedKey, expected);
  }

  Future<void> markSessionExpected() => _setSessionExpected(true);

  Future<void> _saveCredentials(String email, String password) async {
    await _secureStorage.write(key: _storedEmailKey, value: email);
    await _secureStorage.write(key: _storedPasswordKey, value: password);
  }

  Future<void> _clearCredentials() async {
    await _secureStorage.delete(key: _storedEmailKey);
    await _secureStorage.delete(key: _storedPasswordKey);
  }

  Future<bool> hasStoredCredentials() async {
    final email = await _secureStorage.read(key: _storedEmailKey);
    final password = await _secureStorage.read(key: _storedPasswordKey);
    return email?.isNotEmpty == true && password?.isNotEmpty == true;
  }

  Future<User?> _restoreWithStoredCredentials() async {
    final email = await _secureStorage.read(key: _storedEmailKey);
    final password = await _secureStorage.read(key: _storedPasswordKey);
    if (email?.isNotEmpty != true || password?.isNotEmpty != true) {
      return null;
    }

    try {
      final credential = await _auth
          .signInWithEmailAndPassword(email: email!, password: password!)
          .timeout(const Duration(seconds: 6));
      _cachedUser = credential.user;
      await _setSessionExpected(true);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'user-not-found' ||
          e.code == 'user-disabled') {
        await _clearCredentials();
        await _setSessionExpected(false);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<User?> restoredUser({
    Duration normalTimeout = const Duration(seconds: 2),
    Duration expectedSessionTimeout = const Duration(seconds: 3),
    Duration secureFallbackDelay = const Duration(milliseconds: 800),
  }) async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;

    final expectedSession = await isSessionExpected();
    final storedCredentials = expectedSession && await hasStoredCredentials();
    final timeout = storedCredentials
        ? secureFallbackDelay
        : expectedSession
        ? expectedSessionTimeout
        : normalTimeout;
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final current = _auth.currentUser;
      if (current != null) {
        _cachedUser = current;
        return current;
      }

      try {
        final user = await _auth.idTokenChanges().first.timeout(
          const Duration(milliseconds: 500),
        );
        if (user != null) {
          _cachedUser = user;
          return user;
        }
      } catch (_) {
        // Firebase Auth can need a brief moment to restore persisted Android
        // state after a cold start. Keep polling until the startup window ends.
      }

      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    var current = _auth.currentUser;
    if (current != null) _cachedUser = current;
    if (current != null) return current;

    if (expectedSession) {
      current = await _restoreWithStoredCredentials();
      if (current != null) return current;
    }

    return _cachedUser;
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _setSessionExpected(true);
    await _saveCredentials(email.trim(), password);
    _cachedUser = credential.user;
    return credential;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _setSessionExpected(true);
    await _saveCredentials(email.trim(), password);
    _cachedUser = credential.user;
    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _cachedUser = null;
    await _clearCredentials();
    await _setSessionExpected(false);
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<Map<String, String>> diagnostics() async {
    final raw = _auth.currentUser;
    final cached = _cachedUser;
    final expected = await isSessionExpected();
    final storedCredentials = await hasStoredCredentials();
    final values = <String, String>{
      'time': DateTime.now().toIso8601String(),
      'firebaseApps': Firebase.apps.map((app) => app.name).join(', '),
      'sessionExpected': expected.toString(),
      'storedCredentials': storedCredentials.toString(),
      'rawCurrentUser': raw == null ? 'null' : raw.uid,
      'rawEmail': raw?.email ?? 'null',
      'cachedUser': cached == null ? 'null' : cached.uid,
      'cachedEmail': cached?.email ?? 'null',
    };

    if (raw == null) {
      values['idToken'] = 'no raw user';
      return values;
    }

    try {
      final token = await raw.getIdToken().timeout(const Duration(seconds: 4));
      values['idToken'] = token == null ? 'null' : 'ok (${token.length} chars)';
    } catch (e) {
      values['idToken'] = 'error: $e';
    }

    return values;
  }
}
