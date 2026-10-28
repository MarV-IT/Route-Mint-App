import 'package:flutter/foundation.dart';

/// Receives `help_opened(topicId)`: which features people needed explained,
/// i.e. candidates for a simpler UI.
///
/// The app ships no analytics SDK, and its Google Play Data safety form
/// declares no analytics collection, so the default implementation only logs
/// in debug builds. Forwarding these events anywhere off the device means
/// updating that declaration first.
abstract interface class HelpAnalytics {
  void helpOpened(String topicId);
}

class DebugHelpAnalytics implements HelpAnalytics {
  const DebugHelpAnalytics();

  @override
  void helpOpened(String topicId) {
    if (kDebugMode) debugPrint('[analytics] help_opened(topicId: $topicId)');
  }
}

/// Replace at startup to send events to a real backend.
HelpAnalytics helpAnalytics = const DebugHelpAnalytics();
