import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/constants/app_colors.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_position_quote.dart';

/// "Alocação simulada" — a donut by *ticker*, not by asset category like
/// Wallet's real `AllocationDonutCard`: the simulated portfolio has no
/// asset-type classification for its tickers (see `SimulatedPosition`'s
/// fields), so inventing one here would fabricate a category the backend
/// never reported. A fixed, rotating palette stands in for the per-category
/// color Wallet uses.
class SimulatedAllocationDonutCard extends StatelessWidget {
  const SimulatedAllocationDonutCard({super.key, required this.positionQuotes, required this.totalValue});

  final List<SimulatedPositionQuote> positionQuotes;
  final double totalValue;

  static const List<Color> _palette = [
    AppColors.neonCyan,
    AppColors.neonViolet,
    AppColors.neonPink,
    AppColors.goldenBorder,
    AppColors.neonBlue,
    AppColors.positiveGreen,
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;

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
            Text(
              Translator.translate(AppStrings.simulatedWalletAllocationTitle),
              style: AppTextStyles.bodyEmphasis.copyWith(color: tokens.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Donut(positionQuotes: positionQuotes, totalValue: totalValue, palette: _palette),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < positionQuotes.length; i++)
                        _LegendRow(
                          quote: positionQuotes[i],
                          totalValue: totalValue,
                          color: _palette[i % _palette.length],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Donut extends StatelessWidget {
  const _Donut({required this.positionQuotes, required this.totalValue, required this.palette});

  final List<SimulatedPositionQuote> positionQuotes;
  final double totalValue;
  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return SizedBox(
      width: 124,
      height: 124,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: [
                for (var i = 0; i < positionQuotes.length; i++)
                  PieChartSectionData(
                    value: positionQuotes[i].valueOrCostBasis,
                    color: palette[i % palette.length],
                    radius: 22,
                    showTitle: false,
                  ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 38,
            ),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppFormatters.currency(totalValue, showCents: false),
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.quote, required this.totalValue, required this.color});

  final SimulatedPositionQuote quote;
  final double totalValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final percent = totalValue == 0 ? 0.0 : (quote.valueOrCostBasis / totalValue) * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              quote.position.ticker,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: tokens.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
