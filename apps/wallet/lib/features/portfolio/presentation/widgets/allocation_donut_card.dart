import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:petrimonium/core/constants/app_colors.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/theme/app_radii.dart';
import 'package:petrimonium/core/theme/app_spacing.dart';
import 'package:petrimonium/core/theme/app_text_styles.dart';
import 'package:petrimonium/core/utils/formatters.dart';
import 'package:petrimonium/core/widgets/chart_legend.dart';
import 'package:petrimonium/core/widgets/glass_card.dart';
import 'package:petrimonium/features/portfolio/domain/entities/allocation_slice.dart';
import 'package:petrimonium/features/portfolio/domain/entities/investment_type_display.dart';

/// The Asset Allocation donut: portfolio composition by [AllocationSlice]
/// category, with the total patrimônio centered in the hole and a
/// [ChartLegend] below spelling out each category's share — same card
/// chrome as [WealthEvolutionCard] (`lib/.../wealth_evolution_card.dart`) so
/// the two read as one dashboard, not two unrelated widgets.
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
              'Alocação por Categoria',
              style: AppTextStyles.bodyEmphasis.copyWith(color: tokens.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (allocation.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'Sem dados suficientes para calcular sua alocação.',
                  style: AppTextStyles.label.copyWith(color: tokens.textSecondary),
                ),
              )
            else ...[
              SizedBox(
                height: 180,
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
                              radius: 28,
                              showTitle: false,
                            ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 58,
                      ),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppFormatters.currency(totalValue, showCents: false),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title.copyWith(color: tokens.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Total',
                          style: AppTextStyles.caption.copyWith(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm + 2,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final slice in allocation)
                    ChartLegend(items: [
                      ChartLegendItem(
                        color: slice.type.color,
                        label: '${slice.type.shortLabel} · ${slice.portfolioPercent.toStringAsFixed(0)}%',
                      ),
                    ]),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
