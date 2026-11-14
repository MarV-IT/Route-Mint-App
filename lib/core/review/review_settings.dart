import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import 'review_service.dart';

class ReviewSettings extends StatefulWidget {
  const ReviewSettings({super.key, required this.strings, this.service});
  final AppStrings strings;
  final ReviewService? service;
  @override
  State<ReviewSettings> createState() => _ReviewSettingsState();
}

class _ReviewSettingsState extends State<ReviewSettings> {
  bool _busy = false;
  ReviewService get service => widget.service ?? ReviewService.instance;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.strings.reviewActionFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!service.supported) return const SizedBox.shrink();
    final s = widget.strings;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.star_outline),
            title: Text(s.rateApp),
            subtitle: Text(s.rateAppSubtitle),
            trailing: const Icon(Icons.open_in_new),
            onTap: _busy ? null : () => _run(service.openStoreListing),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(s.automaticReviewRequests),
            subtitle: Text(
              service.state.ratedViaSettings
                  ? s.reviewRequestsStopped
                  : s.automaticReviewRequestsSubtitle,
            ),
            value: service.ready && service.state.automaticEnabled,
            onChanged: _busy || !service.ready || service.state.ratedViaSettings
                ? null
                : (value) => _run(() => service.setOptedOut(!value)),
          ),
        ],
      ),
    );
  }
}
