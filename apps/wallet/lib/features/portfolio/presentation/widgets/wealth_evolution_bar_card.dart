import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/constants/app_colors.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/portfolio/domain/services/monthly_wealth_series.dart';

/// The dashboard's "Evolução do patrimônio": one stacked bar per calendar
/// month over the trailing year, splitting each month's closing value into
/// what was put in (valor aplicado) and what the market added on top (ganho
/// de capital) — the reference design's chart, and a deliberately calmer
/// read than [WealthEvolutionCard]'s interactive line chart.
///
/// A month worth **less** than what was put in can't stack: there is no gain
/// segment to draw. It renders as the invested bar with the shortfall struck
/// off its top in the neutral [AppColorTokens.chartNegative] tone — a market
/// dip is never given an alarm color in Wallet (see `AppPalette`).
class WealthEvolutionBarCard extends StatefulWidget {
  const WealthEvolutionBarCard({super.key, required this.series});

  final List<MonthlyWealthPoint> series;

  @override
  State<WealthEvolutionBarCard> createState() => _WealthEvolutionBarCardState();
}

class _WealthEvolutionBarCardState extends State<WealthEvolutionBarCard> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final series = widget.series;
    final hasShortfall = series.any((m) => m.capitalGain < 0);

    return GlassCard(
      backgroundColor: tokens.surface.withValues(alpha: context.isDarkMode ? 0.62 : 0.94),
      borderColor: AppColors.neonCyan.withValues(alpha: 0.3),
      borderRadius: AppRadii.xl,
      borderWidth: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    Translator.translate(AppStrings.homeWealthBarsTitle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyEmphasis.copyWith(color: tokens.textPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _RangeChip(label: Translator.translate(AppStrings.homeWealthBarsRangeChip)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // One [ChartLegend] per entry inside a [Wrap], rather than a
            // single multi-item legend: the labels are long enough
            // ("Valor aplicado" + "Ganho de capital", three entries once a
            // month is underwater) to overflow a fixed Row on a 390px-wide
            // phone — the width the reference design is drawn at.
            Wrap(
              spacing: AppSpacing.sm + 2,
              runSpacing: AppSpacing.xs,
              children: [
                for (final entry in <ChartLegendItem>[
                  ChartLegendItem(
                    color: AppColors.neonViolet,
                    label: Translator.translate(AppStrings.homeWealthBarsLegendInvested),
                  ),
                  ChartLegendItem(
                    color: AppColors.neonCyan,
                    label: Translator.translate(AppStrings.homeWealthBarsLegendGain),
                  ),
                  if (hasShortfall)
                    ChartLegendItem(
                      color: tokens.chartNegative,
                      label: Translator.translate(AppStrings.homeWealthBarsLegendShortfall),
                    ),
                ])
                  ChartLegend(items: [entry]),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 180,
              child: series.isEmpty
                  ? Center(
                      child: Text(
                        Translator.translate(AppStrings.homeWealthBarsEmpty),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.label.copyWith(color: tokens.textSecondary),
                      ),
                    )
                  : BarChart(
                      _buildChartData(series, tokens),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    ),
            ),
            if (_touchedIndex != null && _touchedIndex! < series.length) ...[
              const SizedBox(height: AppSpacing.md),
              _buildTooltip(series[_touchedIndex!], tokens),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(MonthlyWealthPoint month, AppColorTokens tokens) {
    final gain = month.capitalGain;
    return TooltipSummary(
      accentColor: AppColors.neonCyan,
      children: [
        Text(month.shortLabel, style: AppTextStyles.caption.copyWith(color: tokens.textSecondary)),
        Text(
          '${Translator.translate(AppStrings.homeWealthBarsLegendInvested)}: '
          '${AppFormatters.currency(month.investedCapital, showCents: false)}',
          style: AppTextStyles.label.copyWith(color: AppColors.neonViolet, fontWeight: FontWeight.bold),
        ),
        Text(
          '${Translator.translate(AppStrings.homeWealthBarsLegendGain)}: '
          '${gain >= 0 ? '+' : ''}${AppFormatters.currency(gain, showCents: false)}',
          style: AppTextStyles.label.copyWith(
            color: gain >= 0 ? AppColors.neonCyan : tokens.chartNegative,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  BarChartData _buildChartData(List<MonthlyWealthPoint> series, AppColorTokens tokens) {
    var maxY = 0.0;
    for (final month in series) {
      // The invested bar is what's drawn when the month is underwater, so it
      // sets the ceiling just as much as the portfolio value does.
      final tallest = month.portfolioValue > month.investedCapital ? month.portfolioValue : month.investedCapital;
      if (tallest > maxY) maxY = tallest;
    }
    if (maxY == 0) maxY = 1;
    maxY += maxY * 0.15;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (_) => FlLine(color: tokens.divider, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            interval: maxY / 4,
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                AppFormatters.compactCurrency(value),
                style: TextStyle(color: tokens.textSecondary, fontSize: 9),
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= series.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(series[index].shortLabel, style: TextStyle(color: tokens.textSecondary, fontSize: 9)),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(getTooltipItem: (a, b, c, d) => null),
        touchCallback: (event, response) {
          if (!event.isInterestedForInteractions || response == null || response.spot == null) {
            if (event is FlTapUpEvent || event is FlPanEndEvent || event is FlLongPressEnd) {
              setState(() => _touchedIndex = null);
            }
            return;
          }
          HapticFeedback.selectionClick();
          setState(() => _touchedIndex = response.spot!.touchedBarGroupIndex);
        },
      ),
      barGroups: [
        for (var i = 0; i < series.length; i++) BarChartGroupData(x: i, barRods: [_rodFor(series[i], i, tokens)]),
      ],
    );
  }

  BarChartRodData _rodFor(MonthlyWealthPoint month, int index, AppColorTokens tokens) {
    final highlighted = index == _touchedIndex;
    final invested = month.investedCapital;
    final value = month.portfolioValue;
    final underwater = value < invested;
    final top = underwater ? invested : value;

    return BarChartRodData(
      toY: top,
      fromY: 0,
      width: 16,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      rodStackItems: [
        // Below the waterline: what was actually put in.
        BarChartRodStackItem(
          0,
          underwater ? value : invested,
          AppColors.neonViolet.withValues(alpha: highlighted ? 1 : 0.9),
        ),
        if (underwater)
          // Struck off the top in a neutral tone — never an alarm red.
          BarChartRodStackItem(value, invested, tokens.chartNegative.withValues(alpha: highlighted ? 0.55 : 0.35))
        else
          BarChartRodStackItem(invested, value, AppColors.neonCyan.withValues(alpha: highlighted ? 1 : 0.9)),
      ],
    );
  }
}

/// The static "12 meses" label the design puts opposite the chart title —
/// a statement of the window, not a selector.
class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.textTertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.border),
      ),
      child: Text(label, style: TextStyle(color: tokens.textSecondary, fontSize: 10)),
    );
  }
}
