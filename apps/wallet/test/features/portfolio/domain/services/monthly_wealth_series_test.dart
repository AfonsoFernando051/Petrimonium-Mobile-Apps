import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/portfolio/domain/services/monthly_wealth_series.dart';

HistoryPoint point(DateTime date, {required double invested, required double value}) =>
    HistoryPoint(date: date, investedCapital: invested, portfolioValue: value);

void main() {
  final now = DateTime(2026, 9, 14);

  group('MonthlyWealthSeries.fromHistory', () {
    test('returns nothing for an empty history', () {
      expect(MonthlyWealthSeries.fromHistory(const [], now: now), isEmpty);
    });

    test('keeps the last sample of each calendar month', () {
      final series = MonthlyWealthSeries.fromHistory([
        point(DateTime(2026, 8, 3), invested: 100, value: 110),
        point(DateTime(2026, 8, 28), invested: 150, value: 170),
        point(DateTime(2026, 9, 10), invested: 150, value: 180),
      ], now: now);

      expect(series.map((m) => m.shortLabel), ['08/26', '09/26']);
      expect(series.first.investedCapital, 150);
      expect(series.first.portfolioValue, 170);
      expect(series.last.portfolioValue, 180);
    });

    test('emits no bar for months before the first real sample', () {
      // Only two months of real history — the other ten must not become
      // zero-height bars, which would read as "the portfolio was worth
      // nothing" rather than "we have no data from before you started".
      final series = MonthlyWealthSeries.fromHistory([
        point(DateTime(2026, 8, 3), invested: 100, value: 110),
        point(DateTime(2026, 9, 10), invested: 100, value: 120),
      ], now: now);

      expect(series, hasLength(2));
      expect(series.first.shortLabel, '08/26');
    });

    test('carries the last known value forward across a gap after the first sample', () {
      final series = MonthlyWealthSeries.fromHistory([
        point(DateTime(2026, 7, 5), invested: 100, value: 130),
        point(DateTime(2026, 9, 10), invested: 100, value: 150),
      ], now: now);

      expect(series.map((m) => m.shortLabel), ['07/26', '08/26', '09/26']);
      // August had no sample of its own: the holdings really did exist and
      // really were worth July's closing value during it.
      expect(series[1].portfolioValue, 130);
      expect(series[2].portfolioValue, 150);
    });

    test('drops samples older than the window', () {
      final series = MonthlyWealthSeries.fromHistory([
        point(DateTime(2024, 1, 5), invested: 10, value: 11),
        point(DateTime(2026, 9, 10), invested: 100, value: 150),
      ], now: now);

      expect(series.map((m) => m.shortLabel), contains('09/26'));
      expect(series.map((m) => m.shortLabel), isNot(contains('01/24')));
      expect(series.length, lessThanOrEqualTo(12));
    });

    test('capitalGain is negative when the month closed below what was put in', () {
      final series = MonthlyWealthSeries.fromHistory([
        point(DateTime(2026, 9, 10), invested: 200, value: 180),
      ], now: now);

      expect(series.single.capitalGain, -20);
    });

    test('is insensitive to the order the history arrives in', () {
      final series = MonthlyWealthSeries.fromHistory([
        point(DateTime(2026, 8, 28), invested: 150, value: 170),
        point(DateTime(2026, 8, 3), invested: 100, value: 110),
      ], now: now);

      // August resolves to its later sample, not whichever arrived first.
      expect(series.first.shortLabel, '08/26');
      expect(series.first.portfolioValue, 170);
    });
  });
}
