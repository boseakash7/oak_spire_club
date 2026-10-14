import 'package:flutter_test/flutter_test.dart';
import 'package:oakspire_club/app/data/models/plan_limits.dart';
import 'package:oakspire_club/app/data/plan_pricing.dart';

void main() {
  group('PlanPricing', () {
    test('yearly saving against twelve months', () {
      expect(PlanPricing.yearlySavingPercent(monthly: 3, yearly: 25), 31);
    });

    test('no saving without both plans or when yearly costs more', () {
      expect(PlanPricing.yearlySavingPercent(monthly: null, yearly: 25), isNull);
      expect(PlanPricing.yearlySavingPercent(monthly: 3, yearly: null), isNull);
      expect(PlanPricing.yearlySavingPercent(monthly: 2, yearly: 30), isNull);
      expect(PlanPricing.yearlySavingPercent(monthly: 0, yearly: 25), isNull);
    });

    test('per month and amounts', () {
      expect(PlanPricing.amount(PlanPricing.perMonth(25)), '2.08');
      expect(PlanPricing.amount(25), '25');
      expect(PlanPricing.amount(4.5), '4.50');
    });
  });

  group('PlanLimits.fromJson', () {
    test('reads numbers, strings and flags', () {
      final limits = PlanLimits.fromJson({
        'free': {
          'max_bottles': '2',
          'daily_searches': 10,
          'insights_locked': true,
        },
        'premium': {
          'max_bottles': null,
          'daily_searches': 'null',
          'insights_locked': '0',
        },
      });
      expect(limits.free.maxBottles, 2);
      expect(limits.free.dailySearches, 10);
      expect(limits.free.insightsLocked, isTrue);
      expect(limits.premium.maxBottles, isNull);
      expect(limits.premium.dailySearches, isNull);
      expect(limits.premium.insightsLocked, isFalse);
    });

    test('0, blank and missing mean unlimited', () {
      final limits = PlanLimits.fromJson({
        'free': {'max_bottles': 0, 'daily_searches': '', 'insights_locked': 1},
      });
      expect(limits.free.maxBottles, isNull);
      expect(limits.free.dailySearches, isNull);
      expect(limits.free.insightsLocked, isTrue);
      expect(limits.premium.insightsLocked, isFalse);
    });
  });

  group('comparisonRows', () {
    test('one row per difference, in order', () {
      const limits = PlanLimits(
        free: PlanTierLimits(
          maxBottles: 2,
          dailySearches: 10,
          insightsLocked: true,
        ),
        premium: PlanTierLimits(),
      );
      final rows = limits.comparisonRows();
      expect(rows.map((r) => r.kind), [
        PlanFeature.collection,
        PlanFeature.insights,
        PlanFeature.searches,
      ]);
      expect(rows[0].free, 'Up to 2 bottles');
      expect(rows[0].premium, 'Unlimited bottles');
      expect(rows[1].free, 'Bottle insights');
      expect(rows[1].freeLocked, isTrue);
      expect(rows[1].premium, 'Price range, history, deal check');
      expect(rows[1].premiumLocked, isFalse);
      expect(rows[2].free, '10 searches a day');
      expect(rows[2].premium, 'Unlimited searches');
    });

    test('a limit both plans share has no row', () {
      const limits = PlanLimits(
        free: PlanTierLimits(dailySearches: 10),
        premium: PlanTierLimits(),
      );
      expect(limits.comparisonRows().map((r) => r.kind), [PlanFeature.searches]);
    });

    test('the fallback shows insights and searches', () {
      expect(PlanLimits.fallback.comparisonRows().map((r) => r.kind), [
        PlanFeature.insights,
        PlanFeature.searches,
      ]);
    });
  });
}
