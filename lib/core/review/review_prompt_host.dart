import 'dart:async';

import 'package:flutter/material.dart';

import 'review_service.dart';

/// A home marker is absent during authentication, onboarding and the guide.
class ReviewHome extends StatelessWidget {
  const ReviewHome({super.key, required this.enabled, required this.child});
  final bool enabled;
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

class ReviewActivity {
  ReviewActivity({Duration Function()? elapsed})
    : _elapsed = elapsed ?? (Stopwatch()..start()).readElapsed;
  final Duration Function() _elapsed;
  Duration _notBefore = Duration.zero;
  final Set<int> _pointers = {};

  bool get quiet => _pointers.isEmpty && _elapsed() >= _notBefore;
  void defer([Duration duration = const Duration(seconds: 2)]) {
    final until = _elapsed() + duration;
    if (until > _notBefore) _notBefore = until;
  }

  void pointerDown(int pointer) {
    _pointers.add(pointer);
    defer();
  }

  void pointerUp(int pointer) {
    _pointers.remove(pointer);
    defer();
  }

  void pause() {
    _pointers.clear();
    defer(const Duration(seconds: 10));
  }
}

/// Route transitions include paywalls, hints, menus, help and modal dialogs.
class ReviewNavigationObserver extends NavigatorObserver {
  ReviewNavigationObserver(this.activity);
  final ReviewActivity activity;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      activity.defer();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      activity.defer(const Duration(seconds: 30));
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      activity.defer();
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      activity.defer();
  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) => activity.defer();
}

/// Lives above Navigator, survives screen/account rebuilds, and observes all
/// visible feedback, including snackbars hosted by nested Scaffolds.
class ReviewPromptHost extends StatefulWidget {
  const ReviewPromptHost({
    super.key,
    required this.service,
    required this.activity,
    required this.isTracking,
    required this.child,
  });
  final ReviewService service;
  final ReviewActivity activity;
  final bool Function() isTracking;
  final Widget child;
  @override
  State<ReviewPromptHost> createState() => _ReviewPromptHostState();
}

class _ReviewPromptHostState extends State<ReviewPromptHost>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _active = false;
  int _completedTrips = 0;
  bool _wasEligible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _completedTrips = widget.service.state.completedTrips;
    widget.service.addListener(_usageChanged);
    _active =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    widget.activity.pause();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.service.removeListener(_usageChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    widget.activity.pause();
  }

  void _tick() {
    if (!_active) return;
    if (!_screenSafe()) {
      widget.activity.defer();
      return;
    }
    if (!widget.service.eligible) return;
    if (!widget.activity.quiet) return;
    unawaited(
      widget.service.requestIfEligible(
        isSafe: () =>
            mounted && _active && widget.activity.quiet && _screenSafe(),
      ),
    );
  }

  void _usageChanged() {
    final trips = widget.service.state.completedTrips;
    final eligible = widget.service.eligible;
    if (trips > _completedTrips || (eligible && !_wasEligible)) {
      widget.activity.defer();
    }
    _completedTrips = trips;
    _wasEligible = eligible;
  }

  bool _screenSafe() {
    if (!mounted ||
        !_active ||
        widget.isTracking() ||
        MediaQuery.viewInsetsOf(context).bottom > 0) {
      return false;
    }
    var home = false;
    var blocked = false;
    void inspect(Element element) {
      final item = element.widget;
      if (item is Offstage && item.offstage) return;
      if (item is ReviewHome && item.enabled) {
        final route = ModalRoute.of(element);
        home =
            route?.isCurrent == true &&
            route?.animation?.status == AnimationStatus.completed;
      }
      if (item is SnackBar || item is MaterialBanner) {
        // We cannot reliably distinguish success feedback from an error or
        // declined purchase. Give all transient feedback a conservative pause.
        widget.activity.defer(const Duration(seconds: 30));
        blocked = true;
      }
      if (item is Dialog ||
          item is BottomSheet ||
          item is CircularProgressIndicator ||
          item is LinearProgressIndicator ||
          (item is EditableText && item.focusNode.hasFocus)) {
        blocked = true;
      }
      element.visitChildElements(inspect);
    }

    context.visitChildElements(inspect);
    return home && !blocked;
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (event) => widget.activity.pointerDown(event.pointer),
    onPointerUp: (event) => widget.activity.pointerUp(event.pointer),
    onPointerCancel: (event) => widget.activity.pointerUp(event.pointer),
    child: NotificationListener<ScrollNotification>(
      onNotification: (_) {
        widget.activity.defer();
        return false;
      },
      child: widget.child,
    ),
  );
}

extension on Stopwatch {
  Duration readElapsed() => elapsed;
}
