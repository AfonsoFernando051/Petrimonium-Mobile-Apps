import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_position.dart';

/// Pairs a [SimulatedPosition] with its current market price, fetched
/// client-side by `SimulatedWalletController` — the backend's
/// `simulated_portfolio` summary carries only [SimulatedPosition.costBasis]/
/// `averagePrice`, never a live price (see that class's doc comment), so
/// "how much can I gain or lose" only exists once this pairing happens.
///
/// [currentPrice] is `null` when the quote could not be fetched (ticker not
/// found, request failed) — the position then falls back to its cost basis
/// wherever a current value is needed, so one missing quote never breaks the
/// whole portfolio's totals; it just contributes zero (unknown, not
/// fabricated) gain/loss for that position.
class SimulatedPositionQuote {
  const SimulatedPositionQuote({required this.position, required this.currentPrice});

  final SimulatedPosition position;
  final double? currentPrice;

  bool get hasQuote => currentPrice != null;

  double? get currentValue => currentPrice == null ? null : position.quantity * currentPrice!;

  /// Falls back to [SimulatedPosition.costBasis] when there is no quote —
  /// the "assume no gain/loss yet" stand-in used by every total that needs a
  /// value for every position, quoted or not.
  double get valueOrCostBasis => currentValue ?? position.costBasis;

  double? get profit => currentValue == null ? null : currentValue! - position.costBasis;

  double? get profitPercent {
    final profit = this.profit;
    if (profit == null || position.costBasis == 0) return null;
    return (profit / position.costBasis) * 100;
  }
}
