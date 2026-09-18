import 'package:flutter/material.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';

/// "Patrimônio total" headline plus the "quanto pode ganhar ou perder" pair
/// of pills. Mirrors Wallet's real Carteira `_CarteiraSummaryHeader`/
/// `_SummaryPill` layout (a plain column, no card of its own — it sits
/// directly in the screen, same as the real one), with one deliberate
/// addition: pills colored by sign (green/red) instead of always neutral,
/// since reading gain vs. loss at a glance is the whole point of a
/// simulated wallet — teaching that literacy is this tab's job.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Translator.translate(AppStrings.simulatedWalletTotalPatrimonyLabel),
          style: TextStyle(color: tokens.textTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
        ),
        const SizedBox(height: 4),
        Text(
          AppFormatters.currency(totalPatrimony),
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SummaryPill(
              label:
                  '${Translator.translate(AppStrings.simulatedWalletResultLabel)} · ${AppFormatters.currency(totalProfit)}',
              color: profitColor,
            ),
            _SummaryPill(
              label:
                  '${Translator.translate(AppStrings.simulatedWalletReturnLabel)} · '
                  '${AppFormatters.percent(totalProfitPercent)}',
              color: profitColor,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${Translator.translate(AppStrings.simulatedWalletVirtualBalanceLabel)}: ${AppFormatters.currency(virtualBalance)}',
          style: TextStyle(color: tokens.textTertiary, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
