import 'package:flutter/material.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';

/// "Patrimônio total" headline plus the "quanto pode ganhar ou perder" pair
/// of pills — signed result and signed return, both colored by sign
/// (green/red) since reading gain vs. loss at a glance is the whole point
/// of a simulated wallet. Mirrors the real Wallet's `_CarteiraSummaryHeader`
/// layout, with sign-aware pills instead of the real Carteira's
/// always-neutral ones — a deliberate Academy addition, since teaching
/// gain/loss literacy is this tab's job.
class SimulatedWalletKpiHeader extends StatelessWidget {
  const SimulatedWalletKpiHeader({
    super.key,
    required this.totalPatrimony,
    required this.totalProfit,
    required this.totalProfitPercent,
    required this.virtualBalance,
  });

  final double totalPatrimony;
  final double totalProfit;
  final double totalProfitPercent;
  final double virtualBalance;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final profitColor = totalProfit < 0 ? tokens.error : tokens.success;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Translator.translate(AppStrings.simulatedWalletTotalPatrimonyLabel),
            style: AppTextStyles.caption.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppFormatters.currency(totalPatrimony),
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Pill(
                label:
                    '${Translator.translate(AppStrings.simulatedWalletResultLabel)} · ${AppFormatters.currency(totalProfit)}',
                color: profitColor,
              ),
              _Pill(
                label:
                    '${Translator.translate(AppStrings.simulatedWalletReturnLabel)} · '
                    '${AppFormatters.percent(totalProfitPercent)}',
                color: profitColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${Translator.translate(AppStrings.simulatedWalletVirtualBalanceLabel)}: ${AppFormatters.currency(virtualBalance)}',
            style: AppTextStyles.caption.copyWith(color: tokens.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
