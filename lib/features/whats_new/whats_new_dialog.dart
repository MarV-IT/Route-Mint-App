import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/preferences/user_preferences.dart';
import 'whats_new_content.dart';

/// Whether [prefs] belong to someone who updated from an older version and
/// has not seen this version's notes. Brand-new users get the feature guide
/// instead, which marks the notes as seen when it ends.
bool shouldShowWhatsNew(UserPreferences prefs) =>
    prefs.onboardingCompleted &&
    prefs.featureGuideCompleted &&
    prefs.whatsNewSeenVersion != whatsNewVersion;

/// Shows the notes for [whatsNewVersion]. Completes when the window closes,
/// by the close button, a tap outside or Back.
Future<void> showWhatsNewDialog(BuildContext context, AppStrings strings) {
  return showDialog<void>(
    context: context,
    builder: (_) => WhatsNewDialog(strings: strings),
  );
}

class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final items = whatsNewItems(s.currentLanguage);

    final dialogColor =
        theme.dialogTheme.backgroundColor ?? cs.surfaceContainerHigh;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        // Only the close button is pinned, in the top corner. The title
        // scrolls with the list, so at the largest font sizes nothing fixed
        // can outgrow the window and the button never scrolls away.
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    // Keeps the title clear of the close button.
                    padding: const EdgeInsetsDirectional.only(end: 36),
                    child: Semantics(
                      header: true,
                      child: Text(
                        s.whatsNewTitle(whatsNewVersion),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.icon,
                                size: 22,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.body,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            PositionedDirectional(
              top: 8,
              end: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                tooltip: s.close,
                // Same colour as the window, so text scrolling underneath
                // never shows through the button.
                style: IconButton.styleFrom(backgroundColor: dialogColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the notes once over [child] for someone who just updated, then
/// reports it through [onSeen] so they are not shown again.
class WhatsNewGate extends StatefulWidget {
  const WhatsNewGate({
    super.key,
    required this.preferences,
    required this.strings,
    required this.onSeen,
    required this.child,
  });

  final UserPreferences preferences;
  final AppStrings strings;
  final VoidCallback onSeen;
  final Widget child;

  @override
  State<WhatsNewGate> createState() => _WhatsNewGateState();
}

class _WhatsNewGateState extends State<WhatsNewGate> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (!shouldShowWhatsNew(widget.preferences)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _shown) return;
      _shown = true;
      await showWhatsNewDialog(context, widget.strings);
      widget.onSeen();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
