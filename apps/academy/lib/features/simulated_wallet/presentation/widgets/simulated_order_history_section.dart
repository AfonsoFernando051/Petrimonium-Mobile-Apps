import 'package:flutter/material.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/academy_formatters.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_order.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_order_side.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// The simulated wallet's extract: every buy and sell the student has made,
/// newest first, plus the result already booked on the positions they have
/// closed.
///
/// This is the only place a closed position survives. Holdings, the donut and
/// the KPI header are all built from what is *held*, so selling everything
/// emptied the screen and took the outcome of the trade with it — a practice
/// wallet that forgot the practice. The result line is deliberately shown
/// even at zero, so "you have not closed anything yet" reads differently
/// from "you broke even".
class SimulatedOrderHistorySection extends StatelessWidget {
  const SimulatedOrderHistorySection({super.key, required this.orders, required this.realizedResult});

  final List<SimulatedOrder> orders;
  final double realizedResult;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final newestFirst = [...orders]..sort((a, b) => b.executedAt.compareTo(a.executedAt));

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  Translator.translate(AppStrings.simulatedOrderHistoryTitle),
                  style: TextStyle(color: tokens.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              if (newestFirst.isNotEmpty) _RealizedResultPill(value: realizedResult),
            ],
          ),
          const SizedBox(height: 12),
          if (newestFirst.isEmpty)
            Text(
              Translator.translate(AppStrings.simulatedOrderHistoryEmpty),
              style: TextStyle(color: tokens.textSecondary, fontSize: 12),
            )
          else
            for (final order in newestFirst) _OrderRow(order: order),
        ],
      ),
    );
  }
}

class _RealizedResultPill extends StatelessWidget {
  const _RealizedResultPill({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    // Zero is neutral on purpose: painting "nothing closed yet" green would
    // read as a (non-existent) gain.
    final color = value == 0
        ? tokens.textSecondary
        : value > 0
        ? tokens.chartPositive
        : tokens.chartNegative;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(
        '${Translator.translate(AppStrings.simulatedRealizedResultLabel)} · ${AcademyFormatters.currency(value)}',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final SimulatedOrder order;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final isBuy = order.side == SimulatedOrderSide.buy;
    final sideColor = isBuy ? tokens.info : tokens.secondary;
    final sideLabel = Translator.translate(
      isBuy ? AppStrings.simulatedOrderHistoryBuy : AppStrings.simulatedOrderHistorySell,
    );
    // Date only: the backend timestamps execution, but the student chose a
    // trade *date* — showing a time would imply a precision the simulation
    // does not have.
    final date = AcademyFormatters.date(order.executedAt.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: sideColor.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
            child: Icon(isBuy ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 16, color: sideColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$sideLabel · ${order.ticker}',
                  style: TextStyle(color: tokens.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${AcademyFormatters.quantity(order.quantity)} × ${AcademyFormatters.currency(order.price)} · $date',
                  style: TextStyle(color: tokens.textSecondary, fontSize: 10.5),
                ),
              ],
            ),
          ),
          Text(
            AcademyFormatters.currency(order.total),
            style: TextStyle(color: tokens.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
