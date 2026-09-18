import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_order.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_order_side.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_portfolio_summary.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_position_quote.dart';

/// Builds the shared [InvestmentLot] shape (the currency Wallet's real
/// Carteira — `Holding.fromLots`, `WealthHistoryCalculator`, allocation —
/// already runs on) out of the simulated wallet's own data. Nothing here is
/// fabricated: every field traces back to a real fetched position, quote or
/// order; only the *shape* of a single lot per ticker is an approximation.
///
/// One deliberate simplification: this builds **one lot per currently held
/// ticker**, not a full FIFO reconstruction of every buy/sell. The backend's
/// [SimulatedPortfolioSummary] already reports the net current quantity and
/// average price per ticker (post any sells) — exactly what a single lot
/// needs — so the only thing this adds is a purchase date, taken from the
/// earliest BUY order still on record for that ticker. A ticker bought,
/// fully sold, then bought again would show the *later* purchase's date,
/// which under-counts how long the position existed for the wealth-evolution
/// chart — an acceptable approximation given the alternative (replaying the
/// full order ledger) for a practice/teaching tool, not a real portfolio.
abstract final class SimulatedLotBuilder {
  static List<InvestmentLot> build({
    required SimulatedPortfolioSummary portfolio,
    required List<SimulatedPositionQuote> quotes,
    required List<SimulatedOrder> orders,
    required InvestmentTypeEnum Function(String ticker) typeOf,
  }) {
    final earliestBuyDate = <String, DateTime>{};
    for (final order in orders) {
      if (order.side != SimulatedOrderSide.buy) continue;
      final existing = earliestBuyDate[order.ticker];
      if (existing == null || order.executedAt.isBefore(existing)) {
        earliestBuyDate[order.ticker] = order.executedAt;
      }
    }

    final quoteByTicker = {for (final quote in quotes) quote.position.ticker: quote};

    return portfolio.positions.map((position) {
      final quote = quoteByTicker[position.ticker];
      final currentPrice = quote?.currentPrice ?? position.averagePrice;
      final purchaseDate = earliestBuyDate[position.ticker] ?? portfolio.resetAt ?? DateTime.now();

      return InvestmentLot(
        // Synthetic — this lot never round-trips to any backend row, unlike
        // Wallet's real InvestmentLot.id, so it carries no meaning of its own.
        id: 0,
        ticker: position.ticker,
        type: typeOf(position.ticker),
        quantity: position.quantity,
        purchasePrice: position.averagePrice,
        purchaseDate: purchaseDate,
        currentPrice: currentPrice,
        investedValue: position.costBasis,
        currentValue: position.quantity * currentPrice,
        priceStatus: quote?.hasQuote == true ? PriceStatus.live : PriceStatus.stalePurchasePrice,
      );
    }).toList();
  }
}
