import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/help/help_catalog.dart';
import '../../core/legal/legal_links.dart';
import '../../core/localization/app_strings.dart';
import '../../core/subscription/subscription_controller.dart';
import '../../core/subscription/subscription_models.dart';
import '../../shared/utils/safe_scroll_padding.dart';
import '../../shared/widgets/help_hint.dart';
import 'subscription_text.dart';

/// The Pro screen: the paywall for someone without Pro, and the place to
/// see and manage the subscription for someone with it.
///
/// It opens only when a Pro feature is tapped or from Profile, never at
/// launch or over onboarding.
class GoProScreen extends StatefulWidget {
  const GoProScreen({super.key, required this.strings, this.subscription});

  final AppStrings strings;

  /// Defaults to the app-wide controller; tests pass their own.
  final SubscriptionController? subscription;

  @override
  State<GoProScreen> createState() => _GoProScreenState();
}

class _GoProScreenState extends State<GoProScreen> {
  late final SubscriptionController _subscription =
      widget.subscription ?? appSubscription;

  /// Null while the store is being asked.
  List<SubscriptionPlan>? _plans;
  bool _plansFailed = false;
  String? _selectedPlanId;

  /// A purchase or restore is with the store; nothing else may start.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _subscription.addListener(_onSubscriptionChanged);
    if (_subscription.storeEnabled && !_subscription.isPremium) _loadPlans();
  }

  @override
  void dispose() {
    _subscription.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
    if (!mounted) return;
    setState(() {});
    // Pro ended while this screen was open: offer the plans again.
    if (!_subscription.isPremium && _plans == null && !_plansFailed) {
      _loadPlans();
    }
  }

  Future<void> _loadPlans() async {
    setState(() {
      _plans = null;
      _plansFailed = false;
    });
    try {
      final plans = await _subscription.loadPlans();
      if (!mounted) return;
      // Yearly first: it is the better price and the one preselected.
      int rank(SubscriptionPlan plan) =>
          plan.period == PlanPeriod.annual ? 0 : 1;
      plans.sort((a, b) => rank(a).compareTo(rank(b)));
      setState(() {
        _plans = plans;
        _selectedPlanId = plans.isEmpty ? null : plans.first.id;
      });
    } on PurchaseFailure catch (failure) {
      if (kDebugMode) debugPrint('[GoPro] plans failed: $failure');
      if (mounted) setState(() => _plansFailed = true);
    }
  }

  SubscriptionPlan? get _selectedPlan {
    for (final plan in _plans ?? const <SubscriptionPlan>[]) {
      if (plan.id == _selectedPlanId) return plan;
    }
    return null;
  }

  Future<void> _buy(SubscriptionPlan plan) async {
    final s = widget.strings;
    setState(() => _busy = true);
    try {
      await _subscription.purchase(plan);
      if (!mounted) return;
      // The store took the purchase; Pro is normally on already. If its
      // confirmation is still on the way, say so rather than claim it.
      _say(_subscription.isPremium ? s.proActivated : s.purchasePending);
    } on PurchaseFailure catch (failure) {
      if (kDebugMode) debugPrint('[GoPro] purchase failed: $failure');
      if (!mounted) return;
      final message = switch (failure.kind) {
        // Closing the payment sheet is a decision, not an error.
        PurchaseFailureKind.cancelled => null,
        PurchaseFailureKind.pending => s.purchasePending,
        PurchaseFailureKind.network => s.networkErrorCheckConnection,
        PurchaseFailureKind.notAllowed => s.purchaseNotAllowed,
        PurchaseFailureKind.alreadyOwned => s.purchaseAlreadyOwned,
        PurchaseFailureKind.store ||
        PurchaseFailureKind.unknown => s.purchaseFailed,
      };
      if (message != null) _say(message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final s = widget.strings;
    setState(() => _busy = true);
    try {
      final found = await _subscription.restore();
      if (!mounted) return;
      _say(found ? s.purchaseRestored : s.nothingToRestore);
    } on PurchaseFailure catch (failure) {
      if (kDebugMode) debugPrint('[GoPro] restore failed: $failure');
      if (!mounted) return;
      if (failure.kind == PurchaseFailureKind.cancelled) return;
      _say(
        failure.kind == PurchaseFailureKind.network
            ? s.networkErrorCheckConnection
            : s.plansUnavailable,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// The store this device buys from, for the cancellation wording.
  String get _deviceStoreName =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'App Store' : 'Google Play';

  Uri get _manageUri =>
      _subscription.state.managementUrl ??
      (defaultTargetPlatform == TargetPlatform.iOS
          ? Uri.parse('https://apps.apple.com/account/subscriptions')
          : Uri.parse(
              'https://play.google.com/store/account/subscriptions'
              '?package=com.marvroute.app',
            ));

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final subscribed = _subscription.storeEnabled && _subscription.isPremium;
    return Scaffold(
      appBar: AppBar(
        // "Go Pro" is an invitation; a subscriber is looking at their plan.
        title: Text(subscribed ? s.subscription : s.goPro),
        actions: const [HelpHint(HelpTopic.premium)],
      ),
      body: ListView(
        padding: safeScrollPadding(context),
        children: [
          if (_subscription.isTestStore)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(s.testPaymentsNotice),
              ),
            ),
          ...(!_subscription.storeEnabled
              ? _comingSoon(context)
              : _subscription.isPremium
              ? _active(context)
              : _paywall(context)),
        ],
      ),
    );
  }

  // ─── Before the store is switched on ──────────────────────────────────────

  List<Widget> _comingSoon(BuildContext context) {
    final s = widget.strings;
    final theme = Theme.of(context);
    return [
      _Intro(strings: s),
      const SizedBox(height: 12),
      _Benefits(strings: s),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.lock_outline),
        label: Text(s.paymentsComingSoon),
      ),
      const SizedBox(height: 8),
      Text(
        s.testerProHint,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];
  }

  // ─── Paywall ──────────────────────────────────────────────────────────────

  List<Widget> _paywall(BuildContext context) {
    final s = widget.strings;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final plans = _plans;
    final selected = _selectedPlan;

    return [
      _Intro(strings: s),
      const SizedBox(height: 12),
      _Benefits(strings: s),
      const SizedBox(height: 16),
      if (_plansFailed || (plans != null && plans.isEmpty)) ...[
        Text(
          _plansFailed ? s.plansLoadFailed : s.plansUnavailable,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Center(
          child: OutlinedButton.icon(
            onPressed: _loadPlans,
            icon: const Icon(Icons.refresh),
            label: Text(s.retry),
          ),
        ),
      ] else if (plans == null)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        )
      else ...[
        for (final plan in plans)
          _PlanCard(
            strings: s,
            plan: plan,
            savingsPercent: _savingsFor(plan, plans),
            selected: plan.id == _selectedPlanId,
            onSelected: _busy
                ? null
                : () => setState(() => _selectedPlanId = plan.id),
          ),
        const SizedBox(height: 8),
        if (selected != null) ...[
          FilledButton(
            onPressed: _busy ? null : () => _buy(selected),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    selected.trial != null ? s.startFreeTrial : s.subscribeNow,
                  ),
          ),
          const SizedBox(height: 12),
          // Price, period, renewal and how to cancel, next to the button
          // that starts the charge: both stores require all of it here.
          Text(
            _subscription.isTestStore
                ? s.testPaymentsNotice
                : [
                    if (selected.trial case final trial?)
                      s.trialNotice(trialLength(trial, s)),
                    if (selected.period == PlanPeriod.annual)
                      s.subscriptionRenewsYearly(selected.priceText)
                    else
                      s.subscriptionRenewsMonthly(selected.priceText),
                    s.cancelAnytimeIn(_deviceStoreName),
                  ].join(' '),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ],
      const SizedBox(height: 8),
      _Links(strings: s, onRestore: _busy ? null : _restore),
    ];
  }

  int? _savingsFor(SubscriptionPlan plan, List<SubscriptionPlan> plans) {
    if (plan.period != PlanPeriod.annual) return null;
    for (final other in plans) {
      if (other.period == PlanPeriod.monthly) {
        return annualSavingsPercent(plan, other);
      }
    }
    return null;
  }

  // ─── With Pro ─────────────────────────────────────────────────────────────

  List<Widget> _active(BuildContext context) {
    final s = widget.strings;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = _subscription.state;
    final plan = planName(state.period, s);
    final nextStep = subscriptionNextStep(state, s);
    final boughtIn = storeName(state.store);

    return [
      Card(
        elevation: 0,
        color: cs.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    color: cs.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.proActive,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              for (final line in [?plan, ?nextStep]) ...[
                const SizedBox(height: 6),
                Text(
                  line,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      if (state.hasBillingIssue) ...[
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: cs.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: cs.onErrorContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.proBillingIssue,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 12),
      // Bought through a store: it is changed and cancelled there, not here.
      if (boughtIn != null && !_subscription.isTestStore) ...[
        FilledButton.tonalIcon(
          onPressed: () => openLegalLink(context, s, _manageUri),
          icon: const Icon(Icons.open_in_new),
          label: Text(s.manageSubscription),
        ),
        if (boughtIn != _deviceStoreName) ...[
          const SizedBox(height: 8),
          Text(
            s.boughtInStore(boughtIn),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
      _Benefits(strings: s),
      const SizedBox(height: 8),
      _Links(strings: s, showRestore: false),
    ];
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.unlockProTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.unlockProBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final benefits = [
      (Icons.picture_as_pdf_outlined, strings.proUnlimitedReports),
      (Icons.cloud_done_outlined, strings.proCloudBackup),
      (Icons.radar_outlined, strings.proAutoDetection),
      (Icons.local_gas_station_outlined, strings.proFuelSummaries),
      (Icons.checklist_outlined, strings.proMonthlyCloseChecklist),
      (Icons.car_repair_outlined, strings.proMaintenanceReminders),
    ];
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.whatProIncludes,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (final (icon, label) in benefits)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(icon, size: 22, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(label, style: theme.textTheme.bodyLarge),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.strings,
    required this.plan,
    required this.savingsPercent,
    required this.selected,
    required this.onSelected,
  });

  final AppStrings strings;
  final SubscriptionPlan plan;
  final int? savingsPercent;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muted = cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        button: true,
        child: Material(
          color: selected ? cs.secondaryContainer : cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onSelected,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected ? cs.primary : muted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              plan.period == PlanPeriod.annual
                                  ? s.planAnnual
                                  : s.planMonthly,
                              style: theme.textTheme.titleMedium,
                            ),
                            if (savingsPercent case final percent?)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  s.planSavings(percent),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: cs.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // The price with its period is the largest thing
                        // on the card.
                        Text(
                          planPrice(plan, s),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (plan.monthlyPriceText case final monthly?)
                          Text(
                            s.planMonthlyEquivalent(monthly),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: muted,
                            ),
                          ),
                        if (plan.trial case final trial?) ...[
                          const SizedBox(height: 4),
                          Text(
                            s.freeTrialLabel(trialLength(trial, s)),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Restore, Terms and Privacy. Both stores require them on the paywall.
class _Links extends StatelessWidget {
  const _Links({
    required this.strings,
    this.onRestore,
    this.showRestore = true,
  });

  final AppStrings strings;

  /// Null while a purchase is with the store.
  final VoidCallback? onRestore;

  /// False once Pro is on and there is nothing left to restore.
  final bool showRestore;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final language = s.currentLanguage;
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        if (showRestore)
          TextButton(onPressed: onRestore, child: Text(s.restorePurchase)),
        TextButton(
          onPressed: () =>
              openLegalLink(context, s, LegalLinks.termsOfService(language)),
          child: Text(s.termsOfService),
        ),
        TextButton(
          onPressed: () =>
              openLegalLink(context, s, LegalLinks.privacyPolicy(language)),
          child: Text(s.privacyPolicy),
        ),
      ],
    );
  }
}
