import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:petrimonium_wallet/core/constants/app_colors.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/models/investment_type_display.dart';

/// "Ativos na carteira" — portfolio composition by [AllocationSlice]
/// category: a donut with the total patrimônio in its hole, and a legend
/// *beside* it rather than under it, one row per category with its share
/// right-aligned (the reference design's layout — a vertical list reads as
/// a small table of shares, which a wrapped row of chips did not).
///
/// Same card chrome as [WealthEvolutionBarCard] so the two read as one
/// dashboard, not two unrelated widgets.
class AllocationDonutCard extends StatelessWidget {
  const AllocationDonutCard({super.key, required this.allocation, required this.totalValue});

  final List<AllocationSlice> allocation;
  final double totalValue;

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
              Translator.translate(AppStrings.homeAllocationTitle),
              style: AppTextStyles.bodyEmphasis.copyWith(color: tokens.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (allocation.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  Translator.translate(AppStrings.homeAllocationEmpty),
                  style: AppTextStyles.label.copyWith(color: tokens.textSecondary),
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Donut(allocation: allocation, totalValue: totalValue),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [for (final slice in allocation) _LegendRow(slice: slice)],
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
  const _Donut({required this.allocation, required this.totalValue});

  final List<AllocationSlice> allocation;
  final double totalValue;

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
                for (final slice in allocation)
                  PieChartSectionData(
                    value: slice.portfolioPercent,
                    color: slice.type.color,
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Translator.translate(AppStrings.homeAllocationCenterLabel),
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
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
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice});

  final AllocationSlice slice;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: slice.type.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              slice.type.shortLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: tokens.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${slice.portfolioPercent.toStringAsFixed(0)}%',
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
