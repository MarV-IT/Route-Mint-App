import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Native Google account selection. Firebase remains the app's session owner.
class GoogleAuthClient {
  static Future<void>? _initialization;

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _initialize() async {
    try {
      // Client IDs come from google-services.json and the iOS Info.plist.
      await (_initialization ??= GoogleSignIn.instance.initialize());
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  /// Returns null when the user dismisses the account chooser.
  Future<OAuthCredential?> requestCredential() async {
    if (!isSupported) throw UnsupportedError('Google sign-in is unavailable');
    try {
      await _initialize();
      // Let the user choose an account on every explicit sign-in or reauth.
      await GoogleSignIn.instance.signOut();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(code: 'invalid-credential');
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!isSupported) return;
    await _initialize();
    await GoogleSignIn.instance.signOut();
  }
}
