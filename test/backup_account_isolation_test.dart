import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/backup/backup_service.dart';
import 'package:route_mint_app/core/backup/cloud_backup_service.dart';
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
  @override
  User? currentUser = _User('account-a');
}

class _Firestore extends Fake implements FirebaseFirestore {
  final documents = <String, Map<String, dynamic>>{};
  final reads = <String>[];
  final writes = <String>[];
  Future<void> Function()? onSet;
  Future<Map<String, dynamic>?> Function()? onGet;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _Collection(this, collectionPath);
}

// Test double controls delayed server operations without a Firebase backend.
// ignore: subtype_of_sealed_class
class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.db, this.path);

  final _Firestore db;

  @override
  final String path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Reference(db, '${this.path}/$path');
}

// Test double controls delayed server operations without a Firebase backend.
// ignore: subtype_of_sealed_class
class _Reference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _Reference(this.db, this.path);

  final _Firestore db;

  @override
  final String path;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _Collection(db, '$path/$collectionPath');

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    db.writes.add(path);
    db.documents[path] = data;
    await db.onSet?.call();
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    db.reads.add(path);
    return _Snapshot(db.onGet == null ? db.documents[path] : await db.onGet!());
  }
}

// Test double supplies the exact server payload used by each regression case.
// ignore: subtype_of_sealed_class
class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.value);

  final Map<String, dynamic>? value;

  @override
  bool get exists => value != null;

  @override
  Map<String, dynamic>? data() => value;
}

Trip _trip(String id) => Trip(
  id: id,
  from: 'Start',
  to: 'Finish',
  distance: 8,
  category: 'Business',
  date: DateTime(2026, 9, 15),
);

Map<String, dynamic> _backup(String tripId) => {
  'appName': 'MarV Route',
  'backupVersion': 1,
  'trips': [_trip(tripId).toJson()],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Auth auth;
  late _Firestore firestore;
  late CloudBackupService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AccountDataStore.resetForTesting();
    await AccountDataStore.activate('account-a');
    auth = _Auth();
    firestore = _Firestore();
    service = CloudBackupService(auth: auth, firestore: firestore);
  });

  tearDown(AccountDataStore.resetForTesting);

  test(
    'long-lived cloud service backs up each account to its own document',
    () async {
      await TripService().saveTrips([_trip('trip-a')]);
      await service.uploadBackupForCurrentUser();

      auth.currentUser = _User('account-b');
      await AccountDataStore.activate('account-b');
      await TripService().saveTrips([_trip('trip-b')]);
      await service.uploadBackupForCurrentUser();

      expect(firestore.writes, [
        'users/account-a/backups/latest',
        'users/account-b/backups/latest',
      ]);
      expect(
        firestore
            .documents['users/account-a/backups/latest']!['trips'][0]['id'],
        'trip-a',
      );
      expect(
        firestore
            .documents['users/account-b/backups/latest']!['trips'][0]['id'],
        'trip-b',
      );
    },
  );

  test('auth and local storage mismatch prevents upload or restore', () async {
    auth.currentUser = _User('account-b');

    await expectLater(service.uploadBackupForCurrentUser(), throwsStateError);
    await expectLater(service.restoreBackupForCurrentUser(), throwsStateError);
    expect(firestore.writes, isEmpty);
    expect(firestore.reads, isEmpty);
  });

  test('startup restore reads only the current account backup once', () async {
    firestore.documents['users/account-a/backups/latest'] = _backup('trip-a');
    expect(await service.restoreIfLocalDataIsEmpty(), isTrue);
    final accountA = TripService();
    expect((await accountA.loadTrips()).single.id, 'trip-a');
    expect(firestore.reads, ['users/account-a/backups/latest']);

    auth.currentUser = _User('account-b');
    await AccountDataStore.activate('account-b');
    expect(await service.restoreIfLocalDataIsEmpty(), isFalse);
    expect(await TripService().loadTrips(), isEmpty);
    expect((await accountA.loadTrips()).single.id, 'trip-a');
    expect(firestore.reads.last, 'users/account-b/backups/latest');
  });

  testWidgets('offline startup restore times out and ignores a late response', (
    tester,
  ) async {
    final response = Completer<Map<String, dynamic>?>();
    firestore.onGet = () => response.future;
    final restoring = service.restoreIfLocalDataIsEmpty();
    await tester.pump();
    expect(firestore.reads, ['users/account-a/backups/latest']);
    final timedOut = expectLater(restoring, throwsA(isA<TimeoutException>()));
    await tester.pump(const Duration(seconds: 11));

    await timedOut;
    response.complete(_backup('late-trip'));
    await tester.pump();
    expect(await TripService().loadTrips(), isEmpty);
  });

  test('startup restore propagates a failed remote read', () async {
    final offline = StateError('Offline');
    firestore.onGet = () => Future.error(offline);

    await expectLater(
      service.restoreIfLocalDataIsEmpty(),
      throwsA(same(offline)),
    );
    expect(await TripService().loadTrips(), isEmpty);
    expect(firestore.writes, isEmpty);
  });

  test(
    'automatic restore preserves trips saved during a pending read',
    () async {
      final started = Completer<void>();
      final response = Completer<Map<String, dynamic>?>();
      firestore.onGet = () {
        started.complete();
        return response.future;
      };
      final restoring = service.restoreIfLocalDataIsEmpty();
      await started.future;

      await TripService().saveTrips([_trip('new-local-trip')]);
      response.complete(_backup('older-cloud-trip'));

      expect(await restoring, isFalse);
      expect((await TripService().loadTrips()).single.id, 'new-local-trip');
      expect(firestore.writes, isEmpty);
    },
  );

  test(
    'in-flight upload never switches to the next account document',
    () async {
      await TripService().saveTrips([_trip('trip-a')]);
      final started = Completer<void>();
      final finished = Completer<void>();
      firestore.onSet = () {
        started.complete();
        return finished.future;
      };
      final uploading = service.uploadBackupForCurrentUser();
      await started.future;

      auth.currentUser = _User('account-b');
      await AccountDataStore.activate('account-b');
      final rejected = expectLater(uploading, throwsStateError);
      finished.complete();
      await rejected;

      expect(firestore.writes, ['users/account-a/backups/latest']);
      expect(firestore.reads, isEmpty);
      expect(await TripService().loadTrips(), isEmpty);
    },
  );

  for (final nextUid in ['account-b', 'account-a']) {
    test(
      'in-flight restore is rejected after a session change to $nextUid',
      () async {
        final accountA = TripService();
        await accountA.saveTrips([_trip('original-a')]);
        final started = Completer<void>();
        final response = Completer<Map<String, dynamic>?>();
        firestore.onGet = () {
          started.complete();
          return response.future;
        };
        final restoring = service.restoreBackupForCurrentUser();
        await started.future;

        auth.currentUser = null;
        await AccountDataStore.activate(null);
        auth.currentUser = _User(nextUid);
        await AccountDataStore.activate(nextUid);
        final nextAccount = TripService();
        await nextAccount.saveTrips([_trip('current-trip')]);
        final rejected = expectLater(restoring, throwsStateError);
        response.complete(_backup('restored-a'));
        await rejected;

        expect((await nextAccount.loadTrips()).single.id, 'current-trip');
        if (nextUid != 'account-a') {
          expect((await accountA.loadTrips()).single.id, 'original-a');
        }
        expect(firestore.reads, ['users/account-a/backups/latest']);
      },
    );
  }

  test('local import from a stale account screen is rejected', () async {
    final accountA = TripService();
    await accountA.saveTrips([_trip('original-a')]);
    final oldScreenBackup = BackupService();
    await AccountDataStore.activate('account-b');

    await expectLater(
      oldScreenBackup.importBackup(jsonEncode(_backup('imported'))),
      throwsStateError,
    );
    expect(await TripService().loadTrips(), isEmpty);

    await BackupService().importBackup(jsonEncode(_backup('imported')));
    expect((await TripService().loadTrips()).single.id, 'imported');
    expect((await accountA.loadTrips()).single.id, 'original-a');
  });
}
