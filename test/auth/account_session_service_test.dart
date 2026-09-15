import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/auth/account_session_service.dart';
import 'package:route_mint_app/core/storage/account_data_store.dart';
import 'package:route_mint_app/features/trips/models/trip.dart';
import 'package:route_mint_app/features/trips/services/trip_service.dart';
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
  void emit(String? uid) {
    _user = uid == null ? null : _User(uid);
    controller.add(_user);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccountDataStore.resetForTesting();
  });

  test(
    'logout and a new account hide old trips; logging back in restores them',
    () async {
      final auth = _Auth();
      final session = AccountSessionService(
        auth: auth,
        beforeSwitch: () async {},
        afterSwitch: () {},
      );
      addTearDown(session.dispose);
      addTearDown(auth.controller.close);
      auth.emit('A');
      await session.initialize();
      await TripService().addTrip(
        Trip(
          id: 'A-trip',
          from: 'A start',
          to: 'A end',
          distance: 5,
          category: 'business',
          date: DateTime(2026, 9, 15),
        ),
      );
      auth.emit(null);
      expect(session.user, isNull);
      expect(session.isReady, isFalse);
      await session.synchronize();
      expect(await TripService().loadTrips(), isEmpty);
      auth.emit('B');
      await session.synchronize();
      expect(session.user?.uid, 'B');
      expect(await TripService().loadTrips(), isEmpty);
      auth.emit('A');
      await session.synchronize();
      expect((await TripService().loadTrips()).single.id, 'A-trip');
    },
  );

  test('new account stays hidden until old tracking finishes', () async {
    final auth = _Auth();
    final stopped = Completer<void>();
    var stopCalls = 0;
    final session = AccountSessionService(
      auth: auth,
      beforeSwitch: () async {
        if (++stopCalls > 1) await stopped.future;
      },
      afterSwitch: () {},
    );
    addTearDown(session.dispose);
    addTearDown(auth.controller.close);
    auth.emit('A');
    await session.initialize();
    auth.emit('B');
    await Future<void>.delayed(Duration.zero);
    expect(session.isReady, isFalse);
    expect(session.user, isNull);
    expect(AccountDataStore.current.uid, 'A');
    stopped.complete();
    await session.synchronize();
    expect(session.user?.uid, 'B');
    expect(AccountDataStore.current.uid, 'B');
  });

  test('rapid auth events publish only the latest ready account', () async {
    final auth = _Auth();
    final session = AccountSessionService(
      auth: auth,
      beforeSwitch: () async {},
      afterSwitch: () {},
    );
    addTearDown(session.dispose);
    addTearDown(auth.controller.close);
    auth.emit('A');
    await session.initialize();
    final events = <String?>[];
    final listener = session.changes.listen((user) => events.add(user?.uid));
    addTearDown(listener.cancel);
    auth.emit(null);
    auth.emit('B');
    await session.synchronize();
    await Future<void>.delayed(Duration.zero);
    expect(events, ['B']);
    expect(AccountDataStore.current.uid, 'B');
  });

  test('failed account preparation fails closed and can be retried', () async {
    final auth = _Auth();
    var fail = true;
    final session = AccountSessionService(
      auth: auth,
      beforeSwitch: () async {
        if (fail) throw StateError('Cannot save active trip');
      },
      afterSwitch: () {},
    );
    addTearDown(session.dispose);
    addTearDown(auth.controller.close);
    auth.emit('A');
    await expectLater(session.initialize(), throwsStateError);
    expect(session.isReady, isFalse);
    expect(session.user, isNull);
    fail = false;
    await session.retry();
    expect(session.isReady, isTrue);
    expect(session.user?.uid, 'A');
  });

  test(
    'rapid logout and same-account login invalidates the old scope',
    () async {
      final auth = _Auth();
      final session = AccountSessionService(
        auth: auth,
        beforeSwitch: () async {},
        afterSwitch: () {},
      );
      addTearDown(session.dispose);
      addTearDown(auth.controller.close);
      auth.emit('A');
      await session.initialize();
      final original = AccountDataStore.current;
      auth.emit(null);
      auth.emit('A');
      await session.synchronize();
      expect(session.user?.uid, 'A');
      expect(identical(AccountDataStore.current, original), isFalse);
    },
  );
}
