import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/auth/account_deletion_service.dart';
import 'package:route_mint_app/core/auth/account_session_service.dart';
import 'package:route_mint_app/core/auth/auth_service.dart';
import 'package:route_mint_app/core/auth/google_auth_client.dart';
import 'package:route_mint_app/core/backup/cloud_backup_service.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/core/storage/account_data_store.dart';
import 'package:route_mint_app/features/auth/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Provider extends Fake implements UserInfo {
  @override
  String get providerId => 'google.com';
}

class _User extends Fake implements User {
  _User(this.uid);
  @override
  final String uid;
  @override
  List<UserInfo> get providerData => [_Provider()];
  int deleteCalls = 0;
  int reauthCalls = 0;
  AuthCredential? reauthCredential;
  Object? reauthError;
  void Function()? onDeleted;

  @override
  Future<void> delete() async {
    deleteCalls++;
    if (reauthCalls == 0) {
      throw FirebaseAuthException(code: 'requires-recent-login');
    }
    onDeleted?.call();
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    reauthCalls++;
    reauthCredential = credential;
    if (reauthError != null) throw reauthError!;
    return _Credential(this);
  }
}

class _Credential extends Fake implements UserCredential {
  _Credential(this.user);
  @override
  final User? user;
}

class _Auth extends Fake implements FirebaseAuth {
  final controller = StreamController<User?>.broadcast(sync: true);
  @override
  User? currentUser;
  int signInCalls = 0;
  int signOutCalls = 0;
  AuthCredential? receivedCredential;
  Object? signInError;
  User? nextUser;

  @override
  Stream<User?> authStateChanges() => controller.stream;

  void emit(User? user) {
    currentUser = user;
    controller.add(user);
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    signInCalls++;
    receivedCredential = credential;
    if (signInError != null) throw signInError!;
    emit(nextUser);
    return _Credential(nextUser);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    emit(null);
  }
}

class _Google extends Fake implements GoogleAuthClient {
  OAuthCredential? credential = GoogleAuthProvider.credential(
    idToken: 'test-id-token',
  );
  Object? signOutError;
  int signOutCalls = 0;
  void Function()? onRequest;
  @override
  bool get isSupported => true;
  @override
  Future<OAuthCredential?> requestCredential() async {
    onRequest?.call();
    return credential;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutError != null) throw signOutError!;
  }
}

class _ScreenAuth extends Fake implements AuthService {
  Future<UserCredential?> Function()? onGoogle;
  @override
  bool get supportsGoogleSignIn => true;
  @override
  Future<UserCredential?> signInWithGoogle() => onGoogle!();
}

class _Backup extends Fake implements CloudBackupService {
  int deleteCalls = 0;
  @override
  Future<void> deleteBackupForCurrentUser() async {
    deleteCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Auth auth;
  late _Google google;
  late AccountSessionService session;
  late AuthService service;
  const storage = FlutterSecureStorage();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'auth_email': 'previous@example.test',
      'auth_password': 'previous-password',
    });
    AccountDataStore.resetForTesting();
    auth = _Auth();
    google = _Google();
    session = AccountSessionService(
      auth: auth,
      beforeSwitch: () async {},
      afterSwitch: () {},
    );
    service = AuthService(auth: auth, session: session, googleAuth: google);
    auth.emit(null);
    await session.initialize();
  });

  tearDown(() async {
    session.dispose();
    await auth.controller.close();
    AccountDataStore.resetForTesting();
  });

  test(
    'Google sign-in keeps the Firebase UID and removes old password fallback',
    () async {
      final original = _User('existing-firebase-uid');
      auth.nextUser = original;
      final result = await service.signInWithGoogle();
      expect(result?.user, same(original));
      expect(service.currentUser?.uid, 'existing-firebase-uid');
      expect(auth.receivedCredential?.providerId, 'google.com');
      expect(await service.isSessionExpected(), isTrue);
      expect(await storage.read(key: 'auth_email'), isNull);
      expect(await storage.read(key: 'auth_password'), isNull);
    },
  );

  test(
    'canceling Google selection leaves the existing session untouched',
    () async {
      final original = _User('existing-firebase-uid');
      auth.emit(original);
      await session.synchronize();
      google.credential = null;
      expect(await service.signInWithGoogle(), isNull);
      expect(auth.signInCalls, 0);
      expect(service.currentUser, same(original));
      expect(await storage.read(key: 'auth_password'), 'previous-password');
    },
  );

  test(
    'Firebase failure does not mark a completed sign-in or discard credentials',
    () async {
      auth.signInError = FirebaseAuthException(code: 'network-request-failed');
      await expectLater(
        service.signInWithGoogle(),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(await service.isSessionExpected(), isFalse);
      expect(service.currentUser, isNull);
      expect(await storage.read(key: 'auth_password'), 'previous-password');
    },
  );

  test('logout finishes even if native Google cleanup fails', () async {
    auth.emit(_User('google-user'));
    await session.synchronize();
    google.signOutError = StateError('native SDK unavailable');
    await service.signOut();
    expect(auth.signOutCalls, 1);
    expect(google.signOutCalls, 1);
    expect(service.currentUser, isNull);
    expect(await service.isSessionExpected(), isFalse);
    expect(await service.hasStoredCredentials(), isFalse);
  });

  test(
    'deleting a Google account reauthenticates that Firebase user before retrying',
    () async {
      final original = _User('google-user')..onDeleted = () => auth.emit(null);
      auth.emit(original);
      await session.synchronize();
      await service.deleteAccount();
      expect(original.deleteCalls, 2);
      expect(original.reauthCredential?.providerId, 'google.com');
      expect(auth.signInCalls, 0);
      expect(service.currentUser, isNull);
      expect(google.signOutCalls, 1);
    },
  );

  test(
    'choosing a different Google account for deletion never signs it in',
    () async {
      final original = _User('google-user')
        ..reauthError = FirebaseAuthException(code: 'user-mismatch');
      auth.emit(original);
      await session.synchronize();
      await expectLater(
        service.deleteAccount(),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(original.deleteCalls, 1);
      expect(auth.signInCalls, 0);
      expect(service.currentUser, same(original));
    },
  );

  test('canceled deletion reauthentication does not retry deletion', () async {
    final original = _User('google-user');
    auth.emit(original);
    await session.synchronize();
    google.credential = null;
    await expectLater(
      service.deleteAccount(),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(original.deleteCalls, 1);
    expect(original.reauthCalls, 0);
    expect(service.currentUser, same(original));
  });

  test('canceling Google deletion keeps the cloud backup intact', () async {
    final original = _User('google-user');
    auth.emit(original);
    await session.synchronize();
    google.credential = null;
    final backup = _Backup();
    final deletion = AccountDeletionService(
      authService: service,
      cloudBackupService: backup,
    );
    await expectLater(
      deletion.deleteAccountAndData(),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(backup.deleteCalls, 0);
    expect(original.deleteCalls, 0);
    expect(service.currentUser, same(original));
  });

  test('wrong Google account cannot remove the cloud backup', () async {
    final original = _User('google-user')
      ..reauthError = FirebaseAuthException(code: 'user-mismatch');
    auth.emit(original);
    await session.synchronize();
    final backup = _Backup();
    final deletion = AccountDeletionService(
      authService: service,
      cloudBackupService: backup,
    );
    await expectLater(
      deletion.deleteAccountAndData(),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(backup.deleteCalls, 0);
    expect(original.deleteCalls, 0);
    expect(service.currentUser, same(original));
  });

  test(
    'account change during reauthentication prevents deleting either account',
    () async {
      final original = _User('google-user');
      final other = _User('another-user');
      auth.emit(original);
      await session.synchronize();
      google.onRequest = () => auth.emit(other);
      await expectLater(
        service.deleteAccount(),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(original.deleteCalls, 1);
      expect(original.reauthCalls, 0);
      expect(other.deleteCalls, 0);
      expect(auth.signInCalls, 0);
    },
  );

  testWidgets('Google cancellation re-enables login without success or error', (
    tester,
  ) async {
    final screenAuth = _ScreenAuth();
    final pending = Completer<UserCredential?>();
    screenAuth.onGoogle = () => pending.future;
    var authenticated = 0;
    const strings = AppStrings(AppLanguage.english);
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          strings: strings,
          onContinueAsGuest: () {},
          onAuthenticated: () => authenticated++,
          authService: screenAuth,
        ),
      ),
    );
    final button = find.widgetWithText(
      OutlinedButton,
      strings.continueWithGoogle,
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(authenticated, 0);
    expect(find.text(strings.authenticationFailedTryAgain), findsNothing);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
  });

  testWidgets('invalid Google credential does not ask for a password', (
    tester,
  ) async {
    final screenAuth = _ScreenAuth()
      ..onGoogle = () async =>
          throw FirebaseAuthException(code: 'invalid-credential');
    const strings = AppStrings(AppLanguage.ukrainian);
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          strings: strings,
          onContinueAsGuest: () {},
          authService: screenAuth,
        ),
      ),
    );
    final button = find.widgetWithText(
      OutlinedButton,
      strings.continueWithGoogle,
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text(strings.authenticationFailedTryAgain), findsOneWidget);
    expect(find.text(strings.authWrongPassword), findsNothing);
  });

  testWidgets('Google account conflict gives existing sign-in guidance', (
    tester,
  ) async {
    final screenAuth = _ScreenAuth()
      ..onGoogle = () async => throw FirebaseAuthException(
        code: 'account-exists-with-different-credential',
      );
    const strings = AppStrings(AppLanguage.ukrainian);
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          strings: strings,
          onContinueAsGuest: () {},
          authService: screenAuth,
        ),
      ),
    );
    final button = find.widgetWithText(
      OutlinedButton,
      strings.continueWithGoogle,
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text(strings.authUseExistingSignIn), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
