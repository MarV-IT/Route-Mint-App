import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/core/subscription/subscription_models.dart';
import 'package:route_mint_app/features/subscription/subscription_text.dart';

import 'fakes.dart';

void main() {
  final end = DateTime(2026, 12, 12, 10);
  const day = Duration(days: 1);
  const minute = Duration(minutes: 1);

  group('Pro is on', () {
    test('for the whole period already paid for', () {
      final state = stateWith(expiresAt: end);
      expect(state.isPremiumAt(checkedAt), isTrue);
      expect(state.isPremiumAt(end.subtract(minute)), isTrue);
    });

    test('with no end date at all when access does not expire', () {
      expect(stateWith(expiresAt: null).isPremiumAt(DateTime(2040)), isTrue);
    });

    test('offline past a renewal date, for three days', () {
      // Last heard from the store before the period ended, set to renew.
      final state = stateWith(expiresAt: end);
      expect(state.isPremiumAt(end.add(day)), isTrue);
      expect(state.isPremiumAt(end.add(day * 3).subtract(minute)), isTrue);
      expect(state.isPremiumAt(end.add(day * 3)), isFalse);
    });

    test('while the store keeps saying so after the paid date', () {
      // E.g. a billing grace period: confirmed active after the end date.
      final state = stateWith(expiresAt: end, checked: end.add(day));
      expect(state.isPremiumAt(end.add(day * 2)), isTrue);
      expect(state.isPremiumAt(end.add(day * 4)), isFalse);
    });
  });

  group('Pro is off', () {
    test('when nothing was bought', () {
      expect(SubscriptionState.none.isPremiumAt(checkedAt), isFalse);
    });

    test('the moment a cancelled subscription reaches its end date', () {
      final state = stateWith(expiresAt: end, willRenew: false);
      expect(state.isPremiumAt(end.subtract(minute)), isTrue);
      expect(state.isPremiumAt(end), isFalse);
      expect(state.isPremiumAt(end.add(day)), isFalse);
    });

    test('as soon as the store answers "not active", whatever the dates', () {
      // A refund: the paid-through date is still in the future.
      final refunded = stateWith(entitled: false, expiresAt: end);
      expect(refunded.isPremiumAt(checkedAt), isFalse);
    });
  });

  group('saved state', () {
    test('survives being written and read back', () {
      final state = stateWith(
        period: PlanPeriod.annual,
        expiresAt: end,
        inTrial: true,
        hasBillingIssue: true,
        store: SubscriptionStore.appStore,
        managementUrl: Uri.parse(
          'https://apps.apple.com/account/subscriptions',
        ),
      );
      final restored = SubscriptionState.fromJson(
        jsonDecode(jsonEncode(state.toJson())),
      );
      expect(restored, state);
      expect(restored.isPremiumAt(checkedAt), isTrue);
    });

    test('never grants Pro from a damaged or foreign record', () {
      for (final damaged in <Object?>[
        null,
        'pro',
        42,
        <String, dynamic>{},
        {'entitled': 'true'},
        {'entitled': true},
        {...activeAnnual.toJson()}..remove('expiresAt'),
        {...activeAnnual.toJson(), 'expiresAt': 'not a date'},
        {...activeAnnual.toJson(), 'expiresAt': 2099},
        {...activeAnnual.toJson(), 'checkedAt': null},
        {...activeAnnual.toJson(), 'checkedAt': 'broken'},
        {...activeAnnual.toJson(), 'willRenew': 'true'},
        {'expiresAt': '2099-01-01T00:00:00Z'},
        ['entitled', true],
      ]) {
        expect(
          SubscriptionState.fromJson(damaged).isPremiumAt(checkedAt),
          isFalse,
          reason: '$damaged',
        );
      }
    });

    test('ignores fields it does not understand instead of failing', () {
      final state = SubscriptionState.fromJson({
        ...stateWith(expiresAt: null).toJson(),
        'period': 'weekly',
        'store': 'somewhere',
        'managementUrl': 7,
      });
      expect(state.entitled, isTrue);
      expect(state.period, isNull);
      expect(state.store, SubscriptionStore.other);
      expect(state.expiresAt, isNull);
      expect(state.managementUrl, isNull);
    });
  });

  group('wording', () {
    const uk = AppStrings(AppLanguage.ukrainian);
    const en = AppStrings(AppLanguage.english);

    test('says what happens next with the subscription', () {
      expect(
        subscriptionNextStep(stateWith(expiresAt: end), uk),
        'Поновиться 2026-12-12',
      );
      expect(
        subscriptionNextStep(stateWith(expiresAt: end, willRenew: false), uk),
        'Скасовано. Pro діє до 2026-12-12',
      );
      expect(
        subscriptionNextStep(stateWith(expiresAt: end, inTrial: true), uk),
        'Безкоштовний період до 2026-12-12',
      );
      // A cancelled trial ends; it does not turn into a paid period.
      expect(
        subscriptionNextStep(
          stateWith(expiresAt: end, inTrial: true, willRenew: false),
          uk,
        ),
        'Скасовано. Pro діє до 2026-12-12',
      );
      expect(subscriptionNextStep(stateWith(expiresAt: null), uk), isNull);
    });

    test('prices carry their period', () {
      expect(planPrice(annualPlan, en), r'$39.99 / year');
      expect(planPrice(monthlyPlan, uk), r'$4.99 / місяць');
    });

    test('the saving is rounded down and hidden when it is nothing', () {
      // 39.99 against 12 x 4.99 = 59.88 is 33.2% off.
      expect(annualSavingsPercent(annualPlan, monthlyPlan), 33);

      SubscriptionPlan annual(double price, {String currency = 'USD'}) =>
          SubscriptionPlan(
            id: 'a',
            period: PlanPeriod.annual,
            priceText: '$price',
            price: price,
            currencyCode: currency,
          );
      expect(annualSavingsPercent(annual(59.88), monthlyPlan), isNull);
      expect(annualSavingsPercent(annual(70), monthlyPlan), isNull);
      expect(
        annualSavingsPercent(annual(39.99, currency: 'CAD'), monthlyPlan),
        isNull,
      );
    });

    test('trial lengths are counted correctly in every language', () {
      expect(trialLength(const FreeTrial(7, TrialUnit.day), en), '7 days');
      expect(trialLength(const FreeTrial(1, TrialUnit.day), en), '1 day');
      expect(trialLength(const FreeTrial(1, TrialUnit.month), en), '1 month');
      expect(trialLength(const FreeTrial(7, TrialUnit.day), uk), '7 днів');
      expect(trialLength(const FreeTrial(3, TrialUnit.day), uk), '3 дні');
      expect(trialLength(const FreeTrial(1, TrialUnit.week), uk), '1 тиждень');
      expect(trialLength(const FreeTrial(2, TrialUnit.week), uk), '2 тижні');
      expect(trialLength(const FreeTrial(1, TrialUnit.month), uk), '1 місяць');
      for (final language in AppLanguage.values) {
        for (final unit in TrialUnit.values) {
          final text = trialLength(FreeTrial(14, unit), AppStrings(language));
          expect(text, startsWith('14 '), reason: '$language $unit');
          expect(text.length, greaterThan(4), reason: '$language $unit');
        }
      }
    });
  });
}
