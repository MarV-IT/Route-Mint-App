import 'package:flutter/material.dart';

import '../features/reports/platform_breakdown.dart';

/// The one source of platform colours — charts, lists and reports must all
/// read from here so a platform keeps its colour everywhere.
///
/// Values come from the reference data-viz palette and were checked against
/// this app's card surfaces (#eff4f7 light, #171c1f dark) for every pair, not
/// just neighbours: a platform's colour follows it whatever slice ends up next
/// to it. Worst pair: normal-vision ΔE 19.3, red-green ΔE 6.9 (dark). Below 8
/// is only allowed with labels beside every mark, which the charts always
/// show. A fifth hue fails the normal-vision floor, which is why only three
/// platforms are named and the rest share "other work".
///
/// Some light-mode hues sit under 3:1 on the card, so values are never
/// conveyed by colour alone: every slice and bar carries a text label.
class PlatformPalette {
  const PlatformPalette._(this._named, this.otherWork, this.personal);

  static const light = PlatformPalette._(
    [Color(0xFF2A78D6), Color(0xFF008300), Color(0xFFE87BA4)],
    Color(0xFFEDA100),
    Color(0xFF6E6D68),
  );

  static const dark = PlatformPalette._(
    [Color(0xFF3987E5), Color(0xFF008300), Color(0xFFD55181)],
    Color(0xFFC98500),
    Color(0xFFC3C2B7),
  );

  static PlatformPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  final List<Color> _named;
  final Color otherWork;
  final Color personal;

  Color colorFor(PlatformBucket bucket) => switch (bucket.kind) {
    PlatformBucketKind.platform => _named[bucket.colorSlot!],
    PlatformBucketKind.otherWork => otherWork,
    PlatformBucketKind.personal => personal,
  };
}
