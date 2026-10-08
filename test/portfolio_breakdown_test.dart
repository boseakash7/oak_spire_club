import 'package:flutter_test/flutter_test.dart';
import 'package:oakspire_club/app/data/models/collection_item_model.dart';
import 'package:oakspire_club/app/data/portfolio_breakdown.dart';

CollectionItemModel _row({
  required String id,
  String paid = '0',
  String qty = '1',
  String? average,
  String? type,
  String? brand,
  String? distillery,
}) => CollectionItemModel.fromJson({
  'id': id,
  'quantity': qty,
  'price_paid': paid,
  'bluebook': {
    'id': 'b$id',
    'average': average ?? 'null',
    'spirit_type': ?type,
    'brand': ?brand,
    'distillery': ?distillery,
  },
});

void main() {
  group('PortfolioBreakdown.of', () {
    test('shares by type at market value, cost when unpriced', () {
      final slices = PortfolioBreakdown.of([
        _row(id: '1', average: '300', qty: '2', type: 'Bourbon'), // 600
        _row(id: '2', paid: '200', type: 'Rye'), // unpriced: 200
        _row(id: '3', average: '200', type: 'bourbon'), // same group: 200
      ], by: PortfolioGrouping.type);

      expect(slices.map((s) => s.label), ['Bourbon', 'Rye']);
      expect(slices[0].value, 800);
      expect(slices[0].share, 0.8);
      expect(slices[0].bottles, 3);
      expect(slices[1].share, closeTo(0.2, 1e-9));
    });

    test('brand falls back to distillery, then Unspecified', () {
      final slices = PortfolioBreakdown.of([
        _row(id: '1', average: '100', brand: 'Pappy'),
        _row(id: '2', average: '50', distillery: 'Buffalo Trace'),
        _row(id: '3', average: '25'),
      ], by: PortfolioGrouping.brand);

      expect(slices.map((s) => s.label), [
        'Pappy',
        'Buffalo Trace',
        PortfolioBreakdown.unspecified,
      ]);
    });

    test('folds the tail into Other, but never a single group', () {
      final rows = [
        for (var i = 0; i < 7; i++)
          _row(id: '$i', average: '${100 - i}', type: 'T$i'),
      ];
      final slices = PortfolioBreakdown.of(rows, by: PortfolioGrouping.type);
      expect(slices.length, 6);
      expect(slices.last.isOther, isTrue);
      expect(slices.last.value, 95 + 94);
      expect(slices.fold(0.0, (s, e) => s + e.share), closeTo(1, 1e-9));

      final six = PortfolioBreakdown.of(
        rows.take(6),
        by: PortfolioGrouping.type,
      );
      expect(six.map((s) => s.isOther), everyElement(isFalse));
    });

    test('rows worth nothing are left out', () {
      expect(
        PortfolioBreakdown.of([
          _row(id: '1', type: 'Bourbon'),
        ], by: PortfolioGrouping.type),
        isEmpty,
      );
    });
  });

  test('topPriced ranks by one bottle\'s price, not the holding', () {
    final top = PortfolioBreakdown.topPriced([
      _row(id: 'a', average: '100', qty: '10'),
      _row(id: 'b', average: '400'),
      _row(id: 'c', paid: '250'),
      _row(id: 'd'),
    ]);
    expect(top.map((r) => r.id), ['b', 'c', 'a']);
  });
}
