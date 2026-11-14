import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/review/review_service.dart';

import 'review_fakes.dart';

void main() {
  test(
    'an open native flow never blocks trip saves or time checkpoints',
    () async {
      final h = ReviewHarness();
      await h.start(eligible: true);
      final nativeOpened = Completer<void>();
      final nativeClosed = Completer<void>();
      h.gateway.onRequest = nativeOpened.complete;
      h.gateway.completeRequest = () => nativeClosed.future;
      final request = h.service.requestIfEligible(isSafe: () => true);
      await nativeOpened.future;
      await h.service.setForeground(true);
      h.elapsed += const Duration(seconds: 15);
      await Future.wait([
        h.service.checkpoint(),
        h.service.recordCompletedTrip('A', 'saved-during-flow'),
      ]).timeout(const Duration(seconds: 2));
      expect(h.service.state.completedTrips, 1);
      expect(h.service.state.foregroundSeconds, 1815);
      nativeClosed.complete();
      expect(await request, true);
    },
  );
  test('30 minutes OR ten unique completed trips, exact boundaries', () async {
    final h = ReviewHarness();
    await h.start();
    await h.service.setForeground(true);
    h.elapsed = const Duration(minutes: 29, seconds: 59);
    await h.service.checkpoint();
    expect(h.service.eligible, false);
    h.elapsed += const Duration(seconds: 1);
    await h.service.checkpoint();
    expect(h.service.eligible, true);

    final trips = ReviewHarness();
    await trips.start();
    for (var i = 0; i < 9; i++) {
      await trips.service.recordCompletedTrip('A', '$i');
    }
    expect(trips.service.eligible, false);
    await trips.service.recordCompletedTrip('A', '9');
    expect(trips.service.eligible, true);
    expect(trips.service.state.foregroundSeconds, 0);
  });

  test(
    'foreground pauses immediately and preserves subsecond sessions',
    () async {
      final h = ReviewHarness();
      await h.start();
      await h.service.setForeground(true);
      h.elapsed += const Duration(milliseconds: 600);
      final paused = h.service.setForeground(false);
      h.elapsed += const Duration(hours: 8);
      await paused;
      await h.service.checkpoint();
      await h.service.setForeground(true);
      h.elapsed += const Duration(milliseconds: 500);
      h.now = h.now.subtract(const Duration(days: 100));
      await h.service.setForeground(false);
      expect(h.service.state.foregroundMilliseconds, 1100);
      await h.start();
      expect(h.service.state.foregroundMilliseconds, 1100);
    },
  );

  test(
    'concurrent time and trip updates are not lost; owners are independent',
    () async {
      final h = ReviewHarness();
      await h.start();
      await h.service.setForeground(true);
      h.elapsed = const Duration(seconds: 20);
      await Future.wait([
        h.service.checkpoint(),
        h.service.recordCompletedTrip('A', 'same-id'),
        h.service.recordCompletedTrip('A', 'same-id'),
        h.service.recordCompletedTrip('B', 'same-id'),
      ]);
      expect(h.service.state.completedTrips, 2);
      expect(h.service.state.foregroundSeconds, 20);
      await h.start();
      await h.service.recordCompletedTrip('A', 'same-id');
      expect(h.service.state.completedTrips, 2);
    },
  );

  test(
    '90-day cooldown and two requests in a rolling 365 days survive restarts',
    () async {
      final h = ReviewHarness();
      await h.start(eligible: true);
      final first = h.now;
      expect(await h.service.requestIfEligible(isSafe: () => true), true);
      h.now = first
          .add(const Duration(days: 90))
          .subtract(const Duration(seconds: 1));
      await h.start();
      expect(h.service.eligible, false);
      h.now = first.add(const Duration(days: 90));
      expect(await h.service.requestIfEligible(isSafe: () => true), true);
      h.now = first.add(
        const Duration(days: 364, hours: 23, minutes: 59, seconds: 59),
      );
      await h.start();
      expect(h.service.eligible, false);
      h.now = first.add(const Duration(days: 365));
      expect(await h.service.requestIfEligible(isSafe: () => true), true);
      expect(h.service.state.requestAttempts, 3);
      expect(h.service.state.attemptDates, hasLength(2));
      await h.start();
      h.now = first.subtract(const Duration(days: 1));
      expect(h.service.eligible, false);
    },
  );

  test(
    'persist attempt before native call; completion is not proof of rating',
    () async {
      final h = ReviewHarness();
      await h.start(eligible: true);
      h.gateway.onRequest = () {
        final persisted = ReviewState.decode(h.store.value!);
        expect(persisted.requestAttempts, 1);
        expect(persisted.lastRequestAt, h.now);
      };
      await Future.wait([
        h.service.requestIfEligible(isSafe: () => true),
        h.service.requestIfEligible(isSafe: () => true),
      ]);
      expect(h.gateway.requests, 1);
      expect(h.service.state.ratedViaSettings, false);
      h.now = h.now.add(const Duration(days: 400));
      expect(await h.service.requestIfEligible(isSafe: () => true), false);
    },
  );

  test(
    'native failure consumes attempt and never retries in same session',
    () async {
      final h = ReviewHarness();
      await h.start(eligible: true);
      h.gateway.failRequest = true;
      expect(await h.service.requestIfEligible(isSafe: () => true), false);
      expect(h.service.state.requestAttempts, 1);
      expect(await h.service.requestIfEligible(isSafe: () => true), false);
      expect(h.gateway.requests, 1);
    },
  );

  test(
    'unsupported/unavailable does not invoke or consume native quota',
    () async {
      final h = ReviewHarness();
      await h.start(eligible: true);
      h.gateway.supported = false;
      expect(await h.service.requestIfEligible(isSafe: () => true), false);
      h.gateway.supported = true;
      h.gateway.available = false;
      expect(await h.service.requestIfEligible(isSafe: () => true), false);
      expect(await h.service.requestIfEligible(isSafe: () => true), false);
      expect(h.gateway.availabilityChecks, 1);
      expect(h.service.state.requestAttempts, 0);
    },
  );

  test(
    'unsafe UI during availability defers until a later safe moment',
    () async {
      final h = ReviewHarness();
      await h.start(eligible: true);
      final available = Completer<bool>();
      h.gateway.checkAvailability = () => available.future;
      var safe = true;
      final request = h.service.requestIfEligible(isSafe: () => safe);
      safe = false;
      available.complete(true);
      expect(await request, false);
      expect(h.service.state.requestAttempts, 0);
      expect(h.service.eligible, true);
      safe = true;
      expect(await h.service.requestIfEligible(isSafe: () => safe), true);
    },
  );

  test('unsafe UI during persistence rolls back unused reservation', () async {
    final h = ReviewHarness();
    await h.start(eligible: true);
    var safe = true;
    h.store.beforeWrite = (_) async {
      safe = false;
    };
    expect(await h.service.requestIfEligible(isSafe: () => safe), false);
    expect(h.gateway.requests, 0);
    expect(ReviewState.decode(h.store.value!).requestAttempts, 0);
    expect(h.service.eligible, true);
  });

  test('opt-out racing availability wins and survives restart', () async {
    final h = ReviewHarness();
    await h.start(eligible: true);
    final available = Completer<bool>();
    h.gateway.checkAvailability = () => available.future;
    final request = h.service.requestIfEligible(isSafe: () => true);
    await h.service.setOptedOut(true);
    available.complete(true);
    expect(await request, false);
    await h.start();
    expect(h.service.state.optedOut, true);
    expect(h.service.eligible, false);
  });

  test('settings suppression is persisted before leaving for store', () async {
    final h = ReviewHarness();
    await h.start(eligible: true);
    h.gateway.onStore = () {
      expect(ReviewState.decode(h.store.value!).ratedViaSettings, true);
      expect(h.service.eligible, false);
    };
    await h.service.openStoreListing();
    await h.start();
    expect(h.service.state.ratedViaSettings, true);
    expect(h.service.state.requestAttempts, 0);
    expect(h.service.eligible, false);
  });

  test(
    'failed store launch rolls back new suppression but preserves existing flag',
    () async {
      final h = ReviewHarness();
      await h.start(eligible: true);
      h.gateway.failStore = true;
      await expectLater(h.service.openStoreListing(), throwsStateError);
      expect(h.service.state.ratedViaSettings, false);
      h.gateway.failStore = false;
      await h.service.openStoreListing();
      h.gateway.failStore = true;
      await expectLater(h.service.openStoreListing(), throwsStateError);
      expect(h.service.state.ratedViaSettings, true);
    },
  );

  test(
    'corrupt/unreadable storage fails closed and is never overwritten',
    () async {
      final h = ReviewHarness();
      h.store.value = '{broken';
      await h.start();
      expect(h.service.ready, false);
      await h.service.recordCompletedTrip('A', 'one');
      expect(h.store.value, '{broken');
      expect(await h.service.requestIfEligible(isSafe: () => true), false);
      h.store.failRead = true;
      await h.start();
      expect(h.service.ready, false);
    },
  );

  test('failed reservation write never invokes native API', () async {
    final h = ReviewHarness();
    await h.start(eligible: true);
    h.store.failWrite = true;
    expect(await h.service.requestIfEligible(isSafe: () => true), false);
    expect(h.gateway.requests, 0);
    expect(h.service.ready, false);
  });
}
