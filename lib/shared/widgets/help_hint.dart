import 'package:flutter/material.dart';

import '../../core/help/help_analytics.dart';
import '../../core/help/help_catalog.dart';
import '../../core/localization/app_strings_scope.dart';

/// The "?" beside a feature: opens a short explanation right where the
/// question came up, without leaving the screen.
///
/// Takes only the topic; the text comes from [helpCatalog] in the active
/// language. Put it as the last AppBar action, or right after a section
/// title, so it is always in the same spot.
class HelpHint extends StatelessWidget {
  const HelpHint(this.topic, {super.key});

  final HelpTopic topic;

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    // IconButton's 48×48 target clears both minimums (44pt iOS, 48dp
    // Android). The tooltip doubles as the screen-reader label, so it reads
    // "Help: Reports" rather than just "button".
    return IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: s.helpFor(helpTitle(topic, s)),
      onPressed: () => showHelpSheet(context, topic),
    );
  }
}

/// One bottom sheet on both platforms. Closes on a downward swipe, the close
/// button, or a tap outside.
Future<void> showHelpSheet(BuildContext context, HelpTopic topic) {
  helpAnalytics.helpOpened(topic.id);
  return showModalBottomSheet<void>(
    context: context,
    // Lets the sheet grow with the largest system font instead of clipping.
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => HelpSheet(topic: topic),
  );
}

class HelpSheet extends StatelessWidget {
  const HelpSheet({super.key, required this.topic});

  final HelpTopic topic;

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final entry = helpEntry(topic, s.currentLanguage);
    final theme = Theme.of(context);
    final example = entry.example;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A fixed 48px bar holding the drag handle and the close button.
        // Only this bar is pinned: at the largest font sizes even the title
        // can outgrow the sheet, so the title scrolls with the text while
        // the close button stays put.
        SizedBox(
          height: kMinInteractiveDimension,
          child: Stack(
            children: [
              Align(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: s.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.fromSTEB(
              24,
              0,
              24,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    helpTitle(topic, s),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
                Text(entry.body, style: theme.textTheme.bodyLarge),
                if (example != null) ...[
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: s.helpExampleLead,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: example),
                          ],
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
