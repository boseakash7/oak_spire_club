import 'package:flutter_test/flutter_test.dart';
import 'package:oakspire_club/app/core/utils/rating_formatter.dart';
import 'package:oakspire_club/app/data/collection_value_calculator.dart';
import 'package:oakspire_club/app/data/models/collection_item_model.dart';
import 'package:oakspire_club/app/data/models/price_sparkline.dart';

CollectionItemModel _row({
  required String paid,
  required String qty,
  String? average,
}) => CollectionItemModel.fromJson({
  'id': '1',
  'quantity': qty,
  'price_paid': paid,
  'bluebook': {'id': '9', 'average': average ?? 'null'},
});

void main() {
  test('holdingCounts: duplicates, doubled, gaining, losing', () {
    final c = CollectionValueCalculator.holdingCounts([
      _row(paid: '100', qty: '2', average: '250'), // dup, +150%
      _row(paid: '100', qty: '1', average: '120'), // +20%
      _row(paid: '100', qty: '3', average: '80'), // dup, -20%
      _row(paid: '100', qty: '1'), // no market price
      _row(paid: '0', qty: '1', average: '90'), // no price paid
    ]);
    expect(c.duplicates, 2);
    expect(c.doubled, 1);
    expect(c.gaining, 2);
    expect(c.losing, 1);
  });

  group('CollectionValueCalculator.summarize', () {
    test('values priced rows at market, the rest at cost; gain on priced only', () {
      final s = CollectionValueCalculator.summarize([
        _row(paid: '100', qty: '2', average: '150'), // paid 200, worth 300
        _row(paid: '50', qty: '1'), // no market price: counted at 50
      ]);
      expect(s.value, 350);
      expect(s.invested, 250);
      expect(s.valuedAtCostCount, 1);
      expect(s.showingInvestedAsValue, isFalse);
      expect(s.gain, 100);
      expect(s.gainPercent, closeTo(50, 1e-9));
    });

    test('no market price anywhere: headline is invested, no gain', () {
      final s = CollectionValueCalculator.summarize([
        _row(paid: '80', qty: '1'),
      ]);
      expect(s.value, 80);
      expect(s.showingInvestedAsValue, isTrue);
      expect(s.valuedAtCostCount, 0);
      expect(s.gain, isNull);
      expect(s.gainPercent, isNull);
    });
  });

  group('RatingFormatter', () {
    test('shows the 0–100 rating out of 10', () {
      expect(RatingFormatter.label('92'), '9.2');
      expect(RatingFormatter.label('90.00'), '9');
      expect(RatingFormatter.labelOutOfTen('87.5'), '8.8/10');
    });

    test('0, blank and "null" mean not rated', () {
      for (final raw in ['0', '', 'null', null]) {
        expect(RatingFormatter.outOfTen(raw), isNull);
        expect(RatingFormatter.label(raw), '—');
      }
    });
  });

  test('PriceSparkline parses stringly-typed points', () {
    final s = PriceSparkline.fromJson({
      'points': [
        {'d': '2026-07-01', 'p': '100'},
        {'d': '2026-10-01', 'p': 110.5},
      ],
      'change_pct': '10.5',
    });
    expect(s.prices, [100, 110.5]);
    expect(s.isUp, isTrue);
    expect(PriceSparkline.fromJson(s.toJson()).prices, s.prices);
  });
}
