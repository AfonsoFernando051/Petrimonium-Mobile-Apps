import 'package:flutter/material.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/constants/app_colors.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/core/widgets/layer_chip.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/portfolio_controller.dart';

/// The dashboard's four headline numbers, as the 2×2 tile grid the reference
/// design leads with: patrimônio total, lucro total, proventos (12M) and
/// rentabilidade.
///
/// Every figure is real — nothing here is a placeholder. The two tiles that
/// depend on the dividend radar render a "still fetching" state rather than
/// a zero while [PortfolioController.isDividendRadarLoaded] is false: a
/// fabricated `R$ 0,00` sitting where a real number belongs is precisely
/// what the three-layer guardrail exists to prevent.
///
/// The design draws the tiles bare, with no per-tile provenance chip. The
/// product rule that *every* financial figure must state its layer in text
/// is kept by the single [LayerChip] footer below the grid, which covers the
/// whole block at once instead of repeating itself four times.
class PortfolioKpiGrid extends StatelessWidget {
  const PortfolioKpiGrid({super.key, required this.controller});

  final PortfolioController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final summary = controller.summary;
    final proventos = controller.proventos12m;
    final totalProfit = controller.totalProfit;
    final investedCaption =
        '${Translator.translate(AppStrings.homeKpiInvestedPrefix)}: ${AppFormatters.currency(summary.investedCapital)}';
    final capitalCaption =
        '${Translator.translate(AppStrings.homeKpiProfitCapitalPrefix)}: ${AppFormatters.currency(summary.totalGain)}';
    final proventosCaption = proventos == null
        ? Translator.translate(AppStrings.homeKpiAwaitingData)
        : '${Translator.translate(AppStrings.homeKpiProfitProventosPrefix)}: ${AppFormatters.currency(proventos)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _KpiTile(
                  label: Translator.translate(AppStrings.homeKpiTotalWealthLabel),
                  value: AppFormatters.currency(summary.currentValue),
                  valueColor: tokens.textPrimary,
                  highlight: _TodayChange(percent: controller.todayChangePercent),
                  captions: [investedCaption],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiTile(
                  label: Translator.translate(AppStrings.homeKpiTotalProfitLabel),
                  value: totalProfit == null ? '--' : AppFormatters.currency(totalProfit),
                  valueColor: totalProfit == null ? tokens.textTertiary : tokens.primary,
                  captions: [capitalCaption, proventosCaption],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _KpiTile(
                  label: Translator.translate(AppStrings.homeKpiProventosLabel),
                  value: proventos == null ? '--' : AppFormatters.currency(proventos),
                  valueColor: proventos == null ? tokens.textTertiary : tokens.textPrimary,
                  captions: [
                    proventos == null
                        ? Translator.translate(AppStrings.homeKpiAwaitingData)
                        : Translator.translate(AppStrings.homeKpiProventosCaption),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiTile(
                  label: Translator.translate(AppStrings.homeKpiReturnLabel),
                  pills: [
                    _ReturnPill(
                      prefix: Translator.translate(AppStrings.homeKpiReturn12mPrefix),
                      percent: controller.annualChangePercent,
                    ),
                    _ReturnPill(
                      prefix: Translator.translate(AppStrings.homeKpiReturnTotalPrefix),
                      percent: summary.totalGainPercent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: LayerChip(layer: DataLayer.data, label: _provenance(context)),
        ),
      ],
    );
  }

  String _provenance(BuildContext context) {
    final chip = Translator.translate(AppStrings.homeWealthDataChipLabel);
    if (controller.hasStaleQuote) {
      return '$chip · brapi.dev, ${Translator.translate(AppStrings.homeWealthDataStaleSuffix)}';
    }
    final refreshedAt = controller.lastRefreshedAt;
    final time = refreshedAt == null
        ? '--:--'
        : '${refreshedAt.hour.toString().padLeft(2, '0')}:${refreshedAt.minute.toString().padLeft(2, '0')}';
    return '$chip · brapi.dev, hoje $time';
  }
}

/// One tile of the grid. Either [value] (+ optional [highlight]/[captions])
/// or [pills] — the rentabilidade tile shows two pills instead of a single
/// headline figure.
class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    this.value,
    this.valueColor,
    this.highlight,
    this.captions = const [],
    this.pills = const [],
  });

  final String label;
  final String? value;
  final Color? valueColor;
  final Widget? highlight;
  final List<String> captions;
  final List<Widget> pills;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surface.withValues(alpha: context.isDarkMode ? 0.55 : 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: tokens.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
          if (value != null) ...[
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value!,
                style: TextStyle(
                  color: valueColor ?? tokens.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
          if (highlight != null) ...[const SizedBox(height: 3), highlight!],
          for (final caption in captions) ...[
            const SizedBox(height: 6),
            Text(caption, style: TextStyle(color: tokens.textSecondary, fontSize: 10, height: 1.3)),
          ],
          for (final pill in pills) ...[const SizedBox(height: 8), Align(alignment: Alignment.centerLeft, child: pill)],
        ],
      ),
    );
  }
}

/// "+0,48% hoje" under the patrimônio figure. A dip is shown in the neutral
/// [AppColorTokens.chartNegative] tone, never an alarm red — the Wallet
/// product rule spelled out in `AppPalette`.
class _TodayChange extends StatelessWidget {
  const _TodayChange({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final color = percent >= 0 ? AppColors.positiveGreen : tokens.chartNegative;
    return Text(
      '${AppFormatters.percent(percent)} ${Translator.translate(AppStrings.homeKpiTotalWealthTodaySuffix)}',
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    );
  }
}

/// "12M · 8,4%" style pill in the rentabilidade tile.
class _ReturnPill extends StatelessWidget {
  const _ReturnPill({required this.prefix, required this.percent});

  final String prefix;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final color = percent >= 0 ? tokens.primary : tokens.chartNegative;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(
        '$prefix · ${AppFormatters.percentPlain(percent)}',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
