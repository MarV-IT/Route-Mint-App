import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/auth/account_session_service.dart';
import 'package:route_mint_app/core/storage/account_data_store.dart';
import 'package:route_mint_app/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _User extends Fake implements User {
  _User(this.uid);
  @override
  final String uid;
}

class _Auth extends Fake implements FirebaseAuth {
  final controller = StreamController<User?>.broadcast(sync: true);
  User? _user;
  @override
  User? get currentUser => _user;
  @override
  Stream<User?> authStateChanges() => controller.stream;
  void emit(String uid) {
    _user = _User(uid);
    controller.add(_user);
  }
}

void main() {
  testWidgets(
    'account switch removes private routes before the next account opens',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      AccountDataStore.resetForTesting();
      final auth = _Auth();
      final stopping = Completer<void>();
      var switchCount = 0;
      final session = AccountSessionService(
        auth: auth,
        beforeSwitch: () async {
          if (++switchCount > 1) await stopping.future;
        },
        afterSwitch: () {},
      );
      addTearDown(session.dispose);
      addTearDown(auth.controller.close);
      auth.emit('A');
      await tester.runAsync(session.initialize);
      await tester.pumpWidget(RouteMintApp(accountSession: session));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      unawaited(
        Navigator.of(tester.element(find.byType(OnboardingScreen))).push<void>(
          MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Text('Private account A data')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Private account A data'), findsOneWidget);

      auth.emit('B');
      await tester.pump();
      expect(find.text('Private account A data'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(session.isReady, isFalse);

      stopping.complete();
      await tester.pumpAndSettle();
      expect(session.user?.uid, 'B');
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Private account A data'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
