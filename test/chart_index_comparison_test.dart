import 'package:flutter_test/flutter_test.dart';
import 'package:oakspire_club/app/data/chart_index_comparison.dart';

Map<String, dynamic> _p(String date, num price) => {
  'date': date,
  'price': price,
};

void main() {
  test('index aligns as of each market date, backfilling the start', () {
    final aligned = ChartIndexComparison.alignIndexToMarketDates(
      marketPoints: [
        _p('2026-09-01', 1),
        _p('2026-09-02', 1),
        _p('2026-09-04', 1),
        _p('2026-09-05', 1),
      ],
      indexPoints: [
        _p('2026-09-05', 1030),
        _p('2026-09-02', 1000), // out of order on purpose
        _p('2026-09-03', 1010),
      ],
    );
    expect(aligned.map((p) => double.parse(p['price'])), [
      1000, // before the index starts: its first value
      1000,
      1010, // no point on the 4th: the 3rd's carries forward
      1030,
    ]);
  });

  test('no index points, no index line', () {
    expect(
      ChartIndexComparison.alignIndexToMarketDates(
        marketPoints: [_p('2026-09-01', 1)],
        indexPoints: const [],
      ),
      isEmpty,
    );
  });
}
