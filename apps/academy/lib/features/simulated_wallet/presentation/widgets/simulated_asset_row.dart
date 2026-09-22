import 'package:petrimonium_academy/core/utils/academy_formatters.dart';
import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/models/investment_type_display.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/shared/performance_badge.dart';

/// One holding row inside a [SimulatedExpandableCategory]. Ported from
/// Wallet's real `AssetRow` — same ticker-initial avatar (no logo feed for a
/// ticker string), same layout — minus the tap-to-detail navigation: a
/// simulated position has no per-lot edit/delete concept (selling is
/// already the buy/sell toggle on the order screen), so there's nowhere for
/// a tap to usefully go yet.
class SimulatedAssetRow extends StatelessWidget {
  const SimulatedAssetRow({super.key, required this.holding});

  final Holding holding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          _TickerAvatar(ticker: holding.ticker, color: holding.type.color),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.ticker,
                  style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  Translator.translate(
                    AppStrings.simulatedHoldingQuantityPrice,
                    params: {
                      'quantity': AcademyFormatters.quantity(holding.quantity),
                      'price': AcademyFormatters.currency(holding.averagePrice),
                    },
                  ),
                  style: TextStyle(color: tokens.textSecondary, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AcademyFormatters.currency(holding.currentValue, showCents: false),
                  style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  Translator.translate(
                    AppStrings.simulatedHoldingAllocation,
                    params: {'percent': AcademyFormatters.percentPlain(holding.portfolioPercent)},
                  ),
                  style: TextStyle(color: tokens.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // A fallback price makes gainPercent a meaningless 0% — say the quote
          // is missing instead of reporting "no change" the student would read as fact.
          if (holding.hasLiveQuote)
            PerformanceBadge(percent: holding.gainPercent, compact: true)
          else
            UnavailableBadge(
              label: Translator.translate(
                holding.priceStatus == PriceStatus.notQuoted
                    ? AppStrings.holdingNotQuoted
                    : AppStrings.holdingQuoteUnavailable,
              ),
            ),
        ],
      ),
    );
  }
}

class _TickerAvatar extends StatelessWidget {
  const _TickerAvatar({required this.ticker, required this.color});

  final String ticker;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initials = ticker.length >= 2 ? ticker.substring(0, 2) : ticker;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
