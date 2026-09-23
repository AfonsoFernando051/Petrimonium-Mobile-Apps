import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_order.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_order_side.dart';

/// What the student actually made or lost on the simulated positions they
/// have already closed.
///
/// The open positions carry their own unrealised result, which the wallet
/// already shows. A *closed* position leaves nothing behind: it drops out of
/// the portfolio summary entirely, which is why selling everything used to
/// return the wallet to its untouched empty state and quietly take the
/// result of the trade with it. This reads it back out of the order history,
/// the one place it survives.
///
/// Cost basis is the weighted average of the buys up to each sale — the same
/// convention the portfolio's `PM` (preço médio) column already uses, so the
/// two numbers on screen are computed the same way. Never FIFO/LIFO: those
/// would disagree with the average price the student is being shown.
class SimulatedRealizedResultCalculator {
  SimulatedRealizedResultCalculator._();

  /// Realized result across every ticker, positive for gains and negative
  /// for losses — 0 when nothing has been sold yet.
  static double total(List<SimulatedOrder> orders) => byTicker(orders).values.fold(0.0, (sum, value) => sum + value);

  /// Per-ticker realized result, keyed by ticker. Only tickers with at least
  /// one booked sale appear, so a portfolio that has never sold anything
  /// yields an empty map rather than a row of zeroes.
  static Map<String, double> byTicker(List<SimulatedOrder> orders) {
    // The history arrives newest-first from the API; cost basis only means
    // anything walked forwards.
    final chronological = [...orders]..sort((a, b) => a.executedAt.compareTo(b.executedAt));

    final heldQuantity = <String, double>{};
    final heldCost = <String, double>{};
    final realized = <String, double>{};

    for (final order in chronological) {
      final ticker = order.ticker;
      final quantity = heldQuantity[ticker] ?? 0;
      final cost = heldCost[ticker] ?? 0;

      switch (order.side) {
        case SimulatedOrderSide.buy:
          heldQuantity[ticker] = quantity + order.quantity;
          heldCost[ticker] = cost + (order.quantity * order.price);
        case SimulatedOrderSide.sell:
          // A sale with nothing on the books can only come from a seam the
          // backend does not allow (a reset between fetches, say). Booking
          // it at a zero cost basis would report the whole sale as profit,
          // so it is skipped instead.
          if (quantity <= 0) continue;
          final sold = order.quantity > quantity ? quantity : order.quantity;
          final averageCost = cost / quantity;
          realized[ticker] = (realized[ticker] ?? 0) + ((order.price - averageCost) * sold);
          heldQuantity[ticker] = quantity - sold;
          heldCost[ticker] = cost - (averageCost * sold);
      }
    }

    return realized;
  }
}
