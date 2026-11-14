import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ReviewStore {
  Future<String?> read();
  Future<void> write(String value);
}

/// One atomic document, outside account preferences and all app backups.
/// SharedPreferencesAsync uses DataStore on Android and UserDefaults on iOS.
class PreferencesReviewStore implements ReviewStore {
  static const key = 'review_state_v1';
  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _prefs =>
      _preferences ??= SharedPreferencesAsync();
  @override
  Future<String?> read() => _prefs.getString(key);
  @override
  Future<void> write(String value) => _prefs.setString(key, value);
}

abstract interface class ReviewGateway {
  bool get supported;
  Future<bool> isAvailable();
  Future<void> requestReview();
  Future<void> openStoreListing();
}

class NativeReviewGateway implements ReviewGateway {
  // MarV Route's public App Store listing (not the bundle identifier).
  static const appStoreId = '6803331782';
  @override
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();
  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
  @override
  Future<void> openStoreListing() =>
      InAppReview.instance.openStoreListing(appStoreId: appStoreId);
}

class ReviewState {
  const ReviewState({
    this.foregroundMilliseconds = 0,
    this.completedTrips = 0,
    this.requestAttempts = 0,
    this.attemptDates = const [],
    this.countedTrips = const {},
    this.optedOut = false,
    this.ratedViaSettings = false,
  });

  final int foregroundMilliseconds;
  int get foregroundSeconds => foregroundMilliseconds ~/ 1000;
  final int completedTrips;
  final int requestAttempts;
  final List<DateTime> attemptDates;
  final Set<String> countedTrips;
  final bool optedOut;
  // Store opened from Settings, NOT a confirmed rating.
  final bool ratedViaSettings;
  DateTime? get lastRequestAt => attemptDates.lastOrNull;
  bool get automaticEnabled => !optedOut && !ratedViaSettings;

  bool eligibleAt(DateTime now) {
    if (!automaticEnabled ||
        (foregroundSeconds < 30 * 60 && completedTrips < 10)) {
      return false;
    }
    final last = lastRequestAt;
    // Future dates (clock rollback) fail closed as well.
    if (last != null && now.difference(last) < const Duration(days: 90)) {
      return false;
    }
    return attemptDates
            .where((date) => now.difference(date) < const Duration(days: 365))
            .length <
        2;
  }

  ReviewState copyWith({
    int? foregroundMilliseconds,
    int? completedTrips,
    int? requestAttempts,
    List<DateTime>? attemptDates,
    Set<String>? countedTrips,
    bool? optedOut,
    bool? ratedViaSettings,
  }) => ReviewState(
    foregroundMilliseconds:
        foregroundMilliseconds ?? this.foregroundMilliseconds,
    completedTrips: completedTrips ?? this.completedTrips,
    requestAttempts: requestAttempts ?? this.requestAttempts,
    attemptDates: attemptDates ?? this.attemptDates,
    countedTrips: countedTrips ?? this.countedTrips,
    optedOut: optedOut ?? this.optedOut,
    ratedViaSettings: ratedViaSettings ?? this.ratedViaSettings,
  );

  String encode() => jsonEncode({
    'version': 1,
    'review_foregroundSeconds': foregroundSeconds,
    'foregroundRemainderMilliseconds': foregroundMilliseconds % 1000,
    'review_completedTrips': completedTrips,
    'review_lastRequestAt': lastRequestAt?.toIso8601String(),
    'review_requestAttempts': requestAttempts,
    'review_optedOut': optedOut,
    'review_ratedViaSettings': ratedViaSettings,
    'attemptDates': attemptDates.map((date) => date.toIso8601String()).toList(),
    'countedTrips': countedTrips.toList(),
  });

  factory ReviewState.decode(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    if (json['version'] != 1) {
      throw const FormatException('Review state version');
    }
    final seconds = json['review_foregroundSeconds'] as int;
    final remainder = json['foregroundRemainderMilliseconds'] as int;
    final trips = json['review_completedTrips'] as int;
    final attempts = json['review_requestAttempts'] as int;
    final dates =
        (json['attemptDates'] as List)
            .map((date) => DateTime.parse(date as String).toUtc())
            .toList()
          ..sort();
    final counted = (json['countedTrips'] as List).cast<String>().toSet();
    if (seconds < 0 ||
        remainder < 0 ||
        remainder >= 1000 ||
        trips < 0 ||
        attempts < dates.length ||
        (attempts > 0 && dates.isEmpty) ||
        trips != counted.length ||
        json['review_lastRequestAt'] != dates.lastOrNull?.toIso8601String()) {
      throw const FormatException('Invalid review counters');
    }
    return ReviewState(
      foregroundMilliseconds: seconds * 1000 + remainder,
      completedTrips: trips,
      requestAttempts: attempts,
      attemptDates: dates,
      countedTrips: counted,
      optedOut: json['review_optedOut'] as bool,
      ratedViaSettings: json['review_ratedViaSettings'] as bool,
    );
  }
}

/// Installation-wide: account changes and navigation cannot reset quotas.
/// Native APIs never tell us whether their dialog appeared or a rating was sent.
class ReviewService extends ChangeNotifier {
  ReviewService({
    required ReviewStore store,
    required ReviewGateway gateway,
    DateTime Function()? now,
    Duration Function()? elapsed,
  }) : _store = store,
       _gateway = gateway,
       _now = now ?? DateTime.now,
       _elapsed = elapsed ?? (Stopwatch()..start()).elapsedDuration;

  static final instance = ReviewService(
    store: PreferencesReviewStore(),
    gateway: NativeReviewGateway(),
  );
  final ReviewStore _store;
  final ReviewGateway _gateway;
  final DateTime Function() _now;
  final Duration Function() _elapsed;
  ReviewState _state = const ReviewState();
  ReviewState get state => _state;
  bool get supported => _gateway.supported;
  bool _ready = false;
  bool get ready => _ready;
  Future<void>? _initializing;
  Future<void> _pending = Future.value();
  Duration? _foregroundSince;
  bool _attemptedThisSession = false;
  bool _preparing = false;
  bool _manualStoreOpening = false;
  bool _optOutPending = false;

  Future<void> initialize() => _initializing ??= _load();
  Future<void> _load() async {
    try {
      final stored = await _store.read();
      _state = stored == null
          ? const ReviewState()
          : ReviewState.decode(stored);
      _ready = true;
      notifyListeners();
    } catch (_) {
      // Never reset quotas on unreadable storage; disable automatic requests.
      _ready = false;
    }
  }

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _save(ReviewState next) async {
    try {
      await _store.write(next.encode());
      _state = next;
      notifyListeners();
    } catch (_) {
      _ready = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Capture time synchronously: pending writes never extend a foreground
  /// interval across inactive/hidden/paused/detached states.
  Future<void> setForeground(bool active) {
    final elapsed = _elapsed();
    final since = _foregroundSince;
    _foregroundSince = active ? elapsed : null;
    if (since == null) return Future.value();
    return _addForeground(elapsed - since);
  }

  Future<void> checkpoint() => setForeground(_foregroundSince != null);
  Future<void> _addForeground(Duration duration) async {
    if (duration <= Duration.zero) return;
    try {
      await _serial(() async {
        if (!_ready) return;
        await _save(
          _state.copyWith(
            foregroundMilliseconds:
                _state.foregroundMilliseconds + duration.inMilliseconds,
          ),
        );
      });
    } catch (_) {
      /* Rating persistence must never interrupt the app. */
    }
  }

  /// Called only after a new completed trip is durably saved. Bulk restores,
  /// imports, edits and deletions never advance this counter.
  Future<void> recordCompletedTrip(String owner, String tripId) async {
    try {
      await _serial(() async {
        if (!_ready) return;
        final key = jsonEncode([owner, tripId]);
        if (_state.countedTrips.contains(key)) return;
        await _save(
          _state.copyWith(
            completedTrips: _state.completedTrips + 1,
            countedTrips: {..._state.countedTrips, key},
          ),
        );
      });
    } catch (_) {
      /* A saved trip remains successful if rating storage fails. */
    }
  }

  bool get eligible =>
      _ready &&
      !_attemptedThisSession &&
      !_preparing &&
      !_manualStoreOpening &&
      !_optOutPending &&
      supported &&
      _state.eligibleAt(_now().toUtc());

  Future<bool> requestIfEligible({required bool Function() isSafe}) async {
    if (!eligible || !isSafe()) return false;
    _preparing = true;
    try {
      if (!await _gateway.isAvailable()) {
        _attemptedThisSession = true;
        return false;
      }
      Future<bool>? nativeOutcome;
      final started = await _serial(() async {
        if (!_ready ||
            _manualStoreOpening ||
            _optOutPending ||
            !_state.eligibleAt(_now().toUtc()) ||
            !isSafe()) {
          return false;
        }
        final previous = _state;
        final now = _now().toUtc();
        // Persist before invocation so a killed process cannot bypass quotas.
        await _save(
          previous.copyWith(
            requestAttempts: previous.requestAttempts + 1,
            attemptDates: [
              ...previous.attemptDates.where(
                (date) => now.difference(date) < const Duration(days: 365),
              ),
              now,
            ],
          ),
        );
        if (!isSafe() || _manualStoreOpening || _optOutPending) {
          await _save(previous); // Release an unused reservation after a race.
          return false;
        }
        _attemptedThisSession = true;
        // Do not hold the storage queue while a system dialog is open. Trip
        // saves and lifecycle checkpoints must remain independent of its UI.
        nativeOutcome = _gateway.requestReview().then(
          (_) => true,
          onError: (Object _, StackTrace _) => false,
        );
        return true;
      });
      return started ? await nativeOutcome! : false;
    } catch (_) {
      // An invoked native request consumes its attempt even if it fails.
      _attemptedThisSession = true;
      return false;
    } finally {
      _preparing = false;
    }
  }

  Future<void> setOptedOut(bool value) async {
    _optOutPending = value;
    await _serial(() async {
      if (!_ready) throw StateError('Review storage unavailable');
      await _save(_state.copyWith(optedOut: value));
    });
  }

  Future<void> openStoreListing() async {
    if (!supported || _manualStoreOpening) return;
    _manualStoreOpening = true;
    try {
      var wasAlreadyOpened = false;
      await _serial(() async {
        if (!_ready) throw StateError('Review storage unavailable');
        wasAlreadyOpened = _state.ratedViaSettings;
        await _save(_state.copyWith(ratedViaSettings: true));
      });
      try {
        // Save first: the OS may suspend/kill us while the store is opening.
        await _gateway.openStoreListing();
      } catch (_) {
        if (!wasAlreadyOpened) {
          await _serial(() => _save(_state.copyWith(ratedViaSettings: false)));
        }
        rethrow;
      }
    } finally {
      _manualStoreOpening = false;
    }
  }
}

extension on Stopwatch {
  Duration elapsedDuration() => elapsed;
}
