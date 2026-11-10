import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/tax/tax_service.dart';
import '../../shared/utils/currency_utils.dart';
import '../../shared/widgets/summary_card.dart';

/// The tax card on Home.
///
/// United States: the deduction at the IRS standard mileage rate, labelled
/// as an estimate. Canada: no amount at all, only a note that the app keeps
/// the kilometer log — see [TaxService.showsDeductionEstimate] for why.
class DeductionCard extends StatelessWidget {
  const DeductionCard({
    super.key,
    required this.strings,
    required this.country,
    required this.title,
    required this.amount,
    required this.currencyCode,
  });

  final AppStrings strings;
  final Country country;

  /// The label for the chosen period, e.g. "Estimated deduction this week".
  final String title;
  final double amount;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    if (TaxService.showsDeductionEstimate(country)) {
      return SummaryCard(
        title: title,
        value: formatCurrency(amount, currencyCode),
        subtitle: strings.deductionEstimateNote,
      );
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.kilometerLogTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(strings.kilometerLogBody),
          ],
        ),
      ),
    );
  }
}
