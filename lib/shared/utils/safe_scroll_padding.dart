import 'package:flutter/material.dart';

/// Padding for a scrollable that fills a screen with no bottom bar.
///
/// Android 15 forces edge-to-edge for apps targeting SDK 35+, so such a
/// screen draws all the way down and its last item ends up under the
/// gesture/navigation bar. Adding the system inset to the bottom keeps the
/// content reachable while the background still runs edge to edge.
///
/// Screens hosted inside a [Scaffold] that has a `bottomNavigationBar` do not
/// need this: that Scaffold already removes the bottom inset from its body.
EdgeInsets safeScrollPadding(BuildContext context, {double all = 16}) =>
    EdgeInsets.fromLTRB(
      all,
      all,
      all,
      all + MediaQuery.paddingOf(context).bottom,
    );
