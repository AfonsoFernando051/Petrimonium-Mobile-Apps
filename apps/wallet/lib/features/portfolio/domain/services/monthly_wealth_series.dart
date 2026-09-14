import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

/// One calendar month of the "Evolução do patrimônio" bar chart: what had
/// been put in ([investedCapital]) and what it was worth at the end of that
/// month ([portfolioValue]). The two stacked segments of a bar are
/// [investedCapital] and [capitalGain].
class MonthlyWealthPoint {
  const MonthlyWealthPoint({required this.month, required this.investedCapital, required this.portfolioValue});

  /// First day of the month this sample summarises.
  final DateTime month;
  final double investedCapital;
  final double portfolioValue;

  /// Unrealised gain at the end of the month — negative when the portfolio
  /// is worth less than what was put in (rendered as a neutral shortfall
  /// segment, never an alarm color; see `AppPalette`'s `chartNegative`).
  double get capitalGain => portfolioValue - investedCapital;

  /// Two-digit `MM/AA` label under each bar, matching the reference design.
  String get shortLabel => '${month.month.toString().padLeft(2, '0')}/${(month.year % 100).toString().padLeft(2, '0')}';
}

/// Collapses the raw [HistoryPoint] series behind the Wealth Evolution chart
/// into one sample per calendar month, which is what the dashboard's bar
/// chart plots.
abstract final class MonthlyWealthSeries {
  /// Buckets [points] into the trailing [months] calendar months, keeping
  /// the **last** sample inside each month (the month's closing value).
  ///
  /// Two deliberate honesty rules, both about not inventing history:
  ///
  /// * Months **before** the first real sample get no bar at all, rather
  ///   than a zero-height one — the portfolio's value then is unknown, not
  ///   zero, and a flat run of empty bars reads as "I lost everything".
  /// * A gap **after** the first sample carries the previous month's value
  ///   forward. That is not fabrication: the holdings really did exist and
  ///   really were worth that during a month the backend simply did not
  ///   emit a sample for.
  ///
  /// [now] exists for tests; real callers use the default.
  static List<MonthlyWealthPoint> fromHistory(List<HistoryPoint> points, {int months = 12, DateTime? now}) {
    if (points.isEmpty || months <= 0) return const [];

    final reference = now ?? DateTime.now();
    final window = List.generate(months, (i) => DateTime(reference.year, reference.month - (months - 1 - i), 1));

    final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));
    final lastOfMonth = <String, HistoryPoint>{};
    for (final point in sorted) {
      lastOfMonth['${point.date.year}-${point.date.month}'] = point;
    }

    final series = <MonthlyWealthPoint>[];
    HistoryPoint? carried;
    for (final month in window) {
      final sample = lastOfMonth['${month.year}-${month.month}'] ?? carried;
      // Still before the very first real sample — no bar, see the doc above.
      if (sample == null) continue;
      carried = sample;
      series.add(
        MonthlyWealthPoint(
          month: month,
          investedCapital: sample.investedCapital,
          portfolioValue: sample.portfolioValue,
        ),
      );
    }
    return series;
  }
}
