import 'package:flutter/material.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_position_quote.dart';

/// One held position: ticker/quantity/avg price on the left, current value
/// and unrealized gain/loss (colored by sign) on the right — the row that
/// actually answers "how much can I gain or lose" for that position. Falls
/// back to the plain cost basis, uncolored, when [SimulatedPositionQuote]
/// has no current price (see that class's doc for why that can happen).
class SimulatedPositionTile extends StatelessWidget {
  const SimulatedPositionTile({super.key, required this.quote});

  final SimulatedPositionQuote quote;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final position = quote.position;
    final profit = quote.profit;
    final profitColor = profit == null ? tokens.textSecondary : (profit < 0 ? tokens.error : tokens.success);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(position.ticker, style: AppTextStyles.bodyEmphasis.copyWith(color: tokens.textPrimary)),
                Text(
                  '${position.quantity.toStringAsFixed(position.quantity.truncateToDouble() == position.quantity ? 0 : 6)} '
                  '@ ${AppFormatters.currency(position.averagePrice)}',
                  style: AppTextStyles.caption.copyWith(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.currency(quote.valueOrCostBasis),
                style: AppTextStyles.bodyEmphasis.copyWith(color: tokens.textPrimary),
              ),
              Text(
                profit == null
                    ? Translator.translate(AppStrings.simulatedWalletPriceUnavailable)
                    : '${AppFormatters.currency(profit)} (${AppFormatters.percent(quote.profitPercent!)})',
                style: AppTextStyles.caption.copyWith(color: profitColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
