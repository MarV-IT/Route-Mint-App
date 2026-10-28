import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/help/help_catalog.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared/platform_palette.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/widgets/help_hint.dart';
import '../expense_breakdown.dart';
import '../platform_breakdown.dart';

/// Trip share by platform and spending by type, shown at the top of Reports
/// so the tab says something useful before the first report is ever exported.
///
/// One period control scopes both charts. Every slice and bar carries a text
/// label, so nothing depends on colour or on a tap to be read.
class PlatformChartsSection extends StatelessWidget {
  const PlatformChartsSection({
    super.key,
    required this.strings,
    required this.period,
    required this.onPeriodChanged,
    required this.breakdown,
    required this.expenses,
    required this.hasAnyRecords,
    required this.currencyCode,
    required this.onAddTrip,
    required this.onAddExpense,
    required this.onCreateReport,
    this.isCreatingReport = false,
  });

  final AppStrings strings;
  final ChartPeriod period;
  final ValueChanged<ChartPeriod> onPeriodChanged;
  final PlatformBreakdown breakdown;
  final ExpenseBreakdown expenses;

  /// Whether there is any trip, fuel entry or expense at all, in any period.
  final bool hasAnyRecords;
  final String currencyCode;
  final VoidCallback? onAddTrip;
  final VoidCallback? onAddExpense;
  final VoidCallback? onCreateReport;
  final bool isCreatingReport;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final header = Row(
      children: [
        Expanded(
          child: Text(
            s.platformOverview,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        // Right after the section title — the charts are a feature inside
        // Reports, not a screen with an AppBar of their own.
        const HelpHint(HelpTopic.charts),
      ],
    );

    if (!hasAnyRecords) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 10),
          _MessageCard(
            icon: Icons.donut_small_outlined,
            message: s.chartsEmptyMessage,
            action: onAddTrip == null
                ? null
                : FilledButton.icon(
                    onPressed: onAddTrip,
                    icon: const Icon(Icons.add),
                    label: Text(s.addTrip),
                  ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 10),
        SegmentedButton<ChartPeriod>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: ChartPeriod.week, label: Text(s.periodWeek)),
            ButtonSegment(value: ChartPeriod.month, label: Text(s.periodMonth)),
            ButtonSegment(
              value: ChartPeriod.allTime,
              label: Text(s.periodAllTime),
            ),
          ],
          selected: {period},
          onSelectionChanged: (selection) => onPeriodChanged(selection.first),
        ),
        const SizedBox(height: 12),
        if (breakdown.isEmpty)
          _MessageCard(
            icon: Icons.event_busy_outlined,
            message: s.noTripsInPeriod,
            action: period == ChartPeriod.allTime
                ? null
                : TextButton(
                    onPressed: () => onPeriodChanged(ChartPeriod.allTime),
                    child: Text(s.showAllTime),
                  ),
          )
        else
          _TripShareCard(strings: s, breakdown: breakdown),
        const SizedBox(height: 12),
        _ExpenseCard(
          strings: s,
          expenses: expenses,
          currencyCode: currencyCode,
          onAddExpense: onAddExpense,
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: (breakdown.isEmpty && expenses.isEmpty) || isCreatingReport
              ? null
              : onCreateReport,
          icon: isCreatingReport
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf_outlined),
          label: Text(s.createReport),
        ),
      ],
    );
  }
}

String bucketLabel(PlatformBucket bucket, AppStrings s) =>
    switch (bucket.kind) {
      PlatformBucketKind.platform => bucket.name!,
      PlatformBucketKind.otherWork => s.otherWork,
      PlatformBucketKind.personal => s.personalTrips,
    };

String percentLabel(PlatformShare share) =>
    share.isBelowOnePercent ? '<1%' : '${share.percent}%';

class _TripShareCard extends StatelessWidget {
  const _TripShareCard({required this.strings, required this.breakdown});

  final AppStrings strings;
  final PlatformBreakdown breakdown;

  static const _diameter = 168.0;
  static const _ringWidth = 20.0;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final theme = Theme.of(context);
    final palette = PlatformPalette.of(context);
    final total = breakdown.totalTrips;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.tripShareByPlatform, style: theme.textTheme.titleSmall),
            const SizedBox(height: 16),
            Center(
              child: SizedBox.square(
                dimension: _diameter,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // The legend below carries every value as text, so the
                    // ring itself is decorative for screen readers.
                    ExcludeSemantics(
                      child: CustomPaint(
                        size: const Size.square(_diameter),
                        painter: DonutPainter(
                          fractions: [
                            for (final share in breakdown.shares)
                              share.tripCount / total,
                          ],
                          colors: [
                            for (final share in breakdown.shares)
                              palette.colorFor(share.bucket),
                          ],
                          ringWidth: _ringWidth,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(_ringWidth + 12),
                      child: FittedBox(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$total',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              s.tripCountWord(total),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Same order as the ring, clockwise from the top.
            for (final share in breakdown.shares)
              _LegendRow(
                color: palette.colorFor(share.bucket),
                label: bucketLabel(share.bucket, s),
                value:
                    '${s.tripCount(share.tripCount)} · ${percentLabel(share)}',
              ),
          ],
        ),
      ),
    );
  }
}

String expenseKindLabel(ExpenseKind kind, AppStrings s) => switch (kind) {
  ExpenseKind.fuel => s.fuel,
  ExpenseKind.service => s.serviceExpense,
  ExpenseKind.repair => s.repair,
  ExpenseKind.tolls => s.tolls,
  ExpenseKind.parking => s.parking,
};

IconData expenseKindIcon(ExpenseKind kind) => switch (kind) {
  ExpenseKind.fuel => Icons.local_gas_station_outlined,
  ExpenseKind.service => Icons.build_outlined,
  ExpenseKind.repair => Icons.car_repair_outlined,
  ExpenseKind.tolls => Icons.toll_outlined,
  ExpenseKind.parking => Icons.local_parking_outlined,
};

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.strings,
    required this.expenses,
    required this.currencyCode,
    required this.onAddExpense,
  });

  final AppStrings strings;
  final ExpenseBreakdown expenses;
  final String currencyCode;
  final VoidCallback? onAddExpense;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final maxAmount = expenses.shares.first.amount;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.expensesByType, style: theme.textTheme.titleSmall),
            if (expenses.isEmpty) ...[
              const SizedBox(height: 10),
              Text(
                s.noExpensesInPeriod,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
              if (onAddExpense != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: onAddExpense,
                    icon: const Icon(Icons.add),
                    label: Text(s.addExpense),
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 2),
              Text(
                s.expensesTotal(formatCurrency(expenses.total, currencyCode)),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: 14),
              // One series, so one colour: the bars compare amounts, and each
              // row's name and icon say what it is. The app's accent keeps
              // them from reading as one of the platforms in the ring above.
              for (final share in expenses.shares)
                _BarRow(
                  icon: expenseKindIcon(share.kind),
                  color: theme.colorScheme.primary,
                  label: expenseKindLabel(share.kind, s),
                  value: formatCurrency(share.amount, currencyCode),
                  fraction: share.amount / maxAmount,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          // Value sits at the end when it fits and wraps under the name at
          // large text sizes instead of overflowing.
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 2,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.fraction,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  /// Share of the largest row, 0..1. Zero draws no bar at all, so an empty
  /// kind never looks like a small amount.
  final double fraction;

  static const _thickness = 12.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isZero = fraction <= 0;
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label and value above the bar, never inside it, so a short bar
          // can't clip its own text.
          Row(
            children: [
              Icon(icon, size: 20, color: muted),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isZero ? null : FontWeight.w600,
                        color: isZero ? muted : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  // Tiny amounts keep a 4px stub so they stay visible.
                  width: isZero
                      ? 0
                      : math.max(4, constraints.maxWidth * fraction),
                  height: _thickness,
                  decoration: BoxDecoration(
                    color: color,
                    // Rounded at the data end, square at the baseline.
                    borderRadius: const BorderRadiusDirectional.horizontal(
                      end: Radius.circular(4),
                    ).resolve(Directionality.of(context)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 36, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}

/// Draws the share ring: one arc per slice from 12 o'clock, clockwise, with a
/// 2px gap of card surface between slices. A single slice is a full ring.
class DonutPainter extends CustomPainter {
  DonutPainter({
    required this.fractions,
    required this.colors,
    required this.ringWidth,
  });

  final List<double> fractions;
  final List<Color> colors;
  final double ringWidth;

  static const _gapPx = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (math.min(size.width, size.height) - ringWidth) / 2;
    if (radius <= 0) return;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.butt;

    final visible = [
      for (var i = 0; i < fractions.length; i++)
        if (fractions[i] > 0) i,
    ];
    if (visible.isEmpty) return;
    if (visible.length == 1) {
      canvas.drawCircle(center, radius, paint..color = colors[visible.first]);
      return;
    }

    final gap = _gapPx / radius;
    // A slice smaller than the gap would vanish; keep a sliver so every
    // legend row still has a mark.
    final minSweep = 1.5 / radius;
    var start = -math.pi / 2;
    for (final i in visible) {
      final sweep = fractions[i] * 2 * math.pi;
      final drawn = math.max(sweep - gap, math.min(sweep, minSweep));
      canvas.drawArc(
        rect,
        start + (sweep - drawn) / 2,
        drawn,
        false,
        paint..color = colors[i],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(DonutPainter old) =>
      old.ringWidth != ringWidth ||
      !_listEquals(old.fractions, fractions) ||
      !_listEquals(old.colors, colors);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
