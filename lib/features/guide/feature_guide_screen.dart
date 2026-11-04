import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import 'feature_guide_content.dart';

/// A short tour of the main features, shown once after first setup and
/// available again from Profile → Help.
///
/// [onDone] runs whether the tour is finished or skipped; either way it is
/// not shown again on its own.
class FeatureGuideScreen extends StatefulWidget {
  const FeatureGuideScreen({
    super.key,
    required this.strings,
    required this.onDone,
  });

  final AppStrings strings;
  final VoidCallback onDone;

  @override
  State<FeatureGuideScreen> createState() => _FeatureGuideScreenState();
}

class _FeatureGuideScreenState extends State<FeatureGuideScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    // A quick double tap on Skip must not report twice.
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  void _next(int count) {
    if (_page >= count - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final steps = guideSteps(s.currentLanguage);
    final isLast = _page == steps.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip stays in the same corner on every step but the last,
            // where the main button already ends the tour.
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 8, top: 4),
                child: Visibility(
                  visible: !isLast,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(s.skipGuide),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  for (final step in steps) _GuideStepView(step: step),
                ],
              ),
            ),
            _PageDots(
              count: steps.length,
              current: _page,
              label: s.guideStep(_page + 1, steps.length),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _next(steps.length),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(isLast ? s.getStarted : s.next),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideStepView extends StatelessWidget {
  const _GuideStepView({required this.step});

  final GuideStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // Scrolls rather than clips when the system font is very large.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.icon,
                    size: 56,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Semantics(
                header: true,
                child: Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                step.body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.current,
    required this.label,
  });

  final int count;
  final int current;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == current ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == current ? cs.primary : cs.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
