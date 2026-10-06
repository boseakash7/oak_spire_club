import 'package:flutter_test/flutter_test.dart';
import 'package:oakspire_club/app/data/deal_check.dart';
import 'package:oakspire_club/app/data/models/bluebook_model.dart';
import 'package:oakspire_club/app/data/models/bottle_details.dart';
import 'package:oakspire_club/app/data/models/market_models.dart';

DealCheck? _check(double asking) =>
    DealCheck.evaluate(asking: asking, average: 100, low: 80, high: 140);

void main() {
  group('DealCheck.evaluate', () {
    test('nothing to compare without an asking price or an average', () {
      expect(DealCheck.evaluate(asking: null, average: 100), isNull);
      expect(DealCheck.evaluate(asking: 0, average: 100), isNull);
      expect(DealCheck.evaluate(asking: 90, average: null), isNull);
      expect(DealCheck.evaluate(asking: 90, average: 0), isNull);
    });

    test('verdict bands around the average and the range', () {
      expect(_check(70)!.verdict, DealVerdict.belowLow);
      expect(_check(95)!.verdict, DealVerdict.good); // exactly -5%
      expect(_check(96)!.verdict, DealVerdict.fair);
      expect(_check(104)!.verdict, DealVerdict.fair);
      expect(_check(105)!.verdict, DealVerdict.aboveAverage);
      expect(_check(140)!.verdict, DealVerdict.aboveAverage); // at the high
      expect(_check(141)!.verdict, DealVerdict.aboveHigh);
    });

    test('diff and position along the low–high bar', () {
      final c = _check(89)!;
      expect(c.diffPercent, closeTo(-11, 1e-9));
      expect(c.comparisonLabel, '11% under the market average');
      expect(c.position, closeTo(9 / 60, 1e-9));
      expect(c.averagePosition, closeTo(20 / 60, 1e-9));
      expect(_check(500)!.position, 1.0);
      expect(_check(100)!.comparisonLabel, 'At the market average');
    });

    test('a missing or inverted range falls back to the average alone', () {
      final noRange = DealCheck.evaluate(asking: 60, average: 100);
      expect(noRange!.verdict, DealVerdict.good);
      expect(noRange.position, isNull);

      final inverted = DealCheck.evaluate(
        asking: 60,
        average: 100,
        low: 150,
        high: 50,
      );
      expect(inverted!.verdict, DealVerdict.good);
      expect(inverted.low, isNull);
    });
  });

  group('BottleDetails.retailMultiple', () {
    BottleDetails withMsrp(Object? msrp) => BottleDetails.fromBottleJson({
      'details': {'msrp': msrp},
    });

    test('market price over release price', () {
      expect(withMsrp('40').retailMultiple(128), closeTo(3.2, 1e-9));
      expect(withMsrp('40').retailMultipleLabel(128), '3.2× retail');
      expect(withMsrp('40').retailMultipleLabel(30), '0.8× retail');
      expect(withMsrp('100').retailMultipleLabel(1450), '15× retail');
    });

    test('null without both prices', () {
      expect(withMsrp(null).retailMultiple(100), isNull);
      expect(withMsrp('0').retailMultiple(100), isNull);
      expect(withMsrp('40').retailMultiple(null), isNull);
      expect(withMsrp('40').retailMultiple(0), isNull);
    });
  });

  group('market payloads', () {
    test('overview parses the index, movers and their stats', () {
      final o = MarketOverview.fromJson({
        'index': {
          'slug': 'market',
          'name': 'Oak Spire Index',
          'is_headline': true,
          'value': 1025,
          'as_of': '2026-10-05',
          'constituents': '55710',
          'change_1d': 0,
          'change_30d': 2.5,
          'change_365d': null,
          'stale': false,
          'series': [
            {'d': '2026-10-04', 'v': 1000},
            {'d': '2026-10-05', 'v': '1025.0'},
            {'d': 'bad', 'v': 1},
          ],
        },
        'gainers': [
          {
            'id': '1',
            'bottle_name': 'A',
            'average': '115',
            'market': {'change_30d': 25, 'change_90d': null, 'low_365d': 92},
          },
        ],
        'losers': [],
        'window_days': 30,
        'last_updated': {'unix': 1, 'readable': '10.05.2026'},
      });
      expect(o.isEmpty, isFalse);
      expect(o.index!.value, 1025);
      expect(o.index!.constituents, 55710);
      expect(o.index!.changeOver(30), 2.5);
      expect(o.index!.change365d, isNull);
      expect(o.index!.series.length, 2);
      expect(o.gainers.single.market!.change30d, 25);
      expect(o.gainers.single.market!.change90d, isNull);
      expect(o.gainers.single.market!.low365d, 92);
      expect(o.lastUpdated, '10.05.2026');
    });

    test('an overview before the first nightly run is empty', () {
      final o = MarketOverview.fromJson({
        'index': null,
        'gainers': [],
        'losers': [],
      });
      expect(o.isEmpty, isTrue);
      expect(o.windowDays, 30);
    });

    test('a bottle from an older server has no market stats', () {
      final b = BluebookModel.fromJson({'id': 3, 'bottle_name': 'B'});
      expect(b.market, isNull);
    });
  });

  group('MarketHighlights.fromJson', () {
    test('parses breadth, each list and its community figures', () {
      final h = MarketHighlights.fromJson({
        'breadth': {'window_days': '30', 'up': '312', 'down': 140, 'flat': 9},
        'hot': [
          {
            'id': '7',
            'bottle_name': 'Hot',
            'average': '250',
            'market': {'change_30d': 4.5},
            'community': {
              'collectors': null,
              'added_30d': '12',
              'first_priced_on': null,
            },
          },
        ],
        'new': [
          {
            'id': 8,
            'bottle_name': 'New',
            'community': {'first_priced_on': '2026-09-12'},
          },
        ],
        'most_collected': [
          {
            'id': 9,
            'bottle_name': 'Most',
            'community': {'collectors': 48},
          },
        ],
        'top_rated': [
          {'id': 10, 'bottle_name': 'Rated', 'rating': '92'},
        ],
      });

      expect(h.windowDays, 30);
      expect(h.rising, 312);
      expect(h.falling, 140);
      expect(h.flat, 9);
      expect(h.hasBreadth, isTrue);
      expect(h.hot.single.added30d, 12);
      expect(h.hot.single.collectors, isNull);
      expect(h.hot.single.bottle.market?.change30d, 4.5);
      expect(h.newlyPriced.single.firstPricedOn, DateTime(2026, 9, 12));
      expect(h.mostCollected.single.collectors, 48);
      expect(h.topRated.single.bottle.rating, '92');
      expect(h.topRated.single.collectors, isNull);
    });

    test('an empty or partial payload gives empty parts', () {
      for (final json in <Map<String, dynamic>>[
        {},
        {'breadth': 'null', 'hot': 'null', 'new': null, 'top_rated': {}},
      ]) {
        final h = MarketHighlights.fromJson(json);
        expect(h.hasBreadth, isFalse);
        expect(h.windowDays, 30);
        expect(h.hot, isEmpty);
        expect(h.newlyPriced, isEmpty);
        expect(h.mostCollected, isEmpty);
        expect(h.topRated, isEmpty);
      }
    });

    test('"null" strings in a community object read as missing', () {
      final h = MarketHighlights.fromJson({
        'most_collected': [
          {
            'id': 1,
            'bottle_name': 'A',
            'community': {
              'collectors': 'null',
              'added_30d': '',
              'first_priced_on': 'null',
            },
          },
        ],
      });
      final item = h.mostCollected.single;
      expect(item.collectors, isNull);
      expect(item.added30d, isNull);
      expect(item.firstPricedOn, isNull);
    });
  });
}
