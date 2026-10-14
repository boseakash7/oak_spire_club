import 'package:flutter_test/flutter_test.dart';
import 'package:oakspire_club/app/data/models/subscription_package_model.dart';

void main() {
  final received = DateTime(2026, 10, 11, 12);

  Map<String, dynamic> row({Object? offer, Object? trialDays}) => {
    'id': '2',
    'name': 'Premium',
    'price': '25',
    'package_type': 'yearly',
    'apple_store_id': 'yearly_plan',
    'offer': offer,
    'trial_days': ?trialDays,
  };

  group('PackageOffer.fromJson', () {
    test('ends ends_in seconds after it was received', () {
      final offer = PackageOffer.fromJson({
        'price': '18.00',
        'label': 'Launch offer',
        'ends_at': 1791900000,
        'ends_in': 3600,
        'apple_store_id': 'yearly_offer',
      }, receivedAt: received)!;
      expect(offer.price, '18.00');
      expect(offer.label, 'Launch offer');
      expect(offer.endsAt, received.add(const Duration(hours: 1)));
      expect(offer.appleStoreId, 'yearly_offer');
      expect(offer.isRunning(received), isTrue);
      expect(offer.isRunning(received.add(const Duration(hours: 1))), isFalse);
    });

    test('no offer without a price or time left', () {
      expect(PackageOffer.fromJson(null), isNull);
      expect(PackageOffer.fromJson({'price': '0', 'ends_in': 60}), isNull);
      expect(PackageOffer.fromJson({'price': '18', 'ends_in': 0}), isNull);
    });

    test('blank label and Apple id', () {
      final offer = PackageOffer.fromJson({
        'price': '18',
        'label': null,
        'ends_in': 60,
        'apple_store_id': 'null',
      })!;
      expect(offer.label, 'Limited offer');
      expect(offer.appleStoreId, isNull);
    });
  });

  group('SubscriptionPackageModel', () {
    test('charges the offer while it runs, the price after', () {
      final plan = SubscriptionPackageModel.fromJson(
        row(offer: {'price': '18.00', 'ends_in': 60, 'apple_store_id': 'y_off'}),
      );
      final now = DateTime.now();
      expect(plan.chargePriceAt(now), '18.00');
      expect(plan.appleProductIdAt(now), 'y_off');
      final later = now.add(const Duration(minutes: 2));
      expect(plan.offerAt(later), isNull);
      expect(plan.chargePriceAt(later), '25');
      expect(plan.appleProductIdAt(later), 'yearly_plan');
    });

    test('trial days, with the server default when missing', () {
      expect(SubscriptionPackageModel.fromJson(row(trialDays: 3)).trialDays, 3);
      expect(SubscriptionPackageModel.fromJson(row(trialDays: '0')).trialDays, 0);
      expect(
        SubscriptionPackageModel.fromJson(row()).trialDays,
        SubscriptionPackageModel.defaultTrialDays,
      );
    });
  });
}
