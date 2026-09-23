import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_order.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_order_side.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/services/simulated_realized_result_calculator.dart';

/// Closing a simulated position used to erase it: sell everything and the
/// wallet went back to its pristine "add your first asset" state, taking the
/// result of the trade with it. The learner practised a buy and a sell and
/// was told nothing about how it went — which is the single thing a practice
/// wallet exists to tell them.
void main() {
  var nextId = 0;

  SimulatedOrder order(String ticker, SimulatedOrderSide side, double quantity, double price, {DateTime? at}) {
    nextId++;
    return SimulatedOrder(
      id: nextId,
      ticker: ticker,
      side: side,
      quantity: quantity,
      price: price,
      total: quantity * price,
      executedAt: at ?? DateTime(2026, 1, nextId),
      clientOrderId: 'c$nextId',
    );
  }

  setUp(() => nextId = 0);

  group('SimulatedRealizedResultCalculator', () {
    test('is zero when nothing has been sold', () {
      final result = SimulatedRealizedResultCalculator.total([order('PETR4', SimulatedOrderSide.buy, 10, 48.09)]);

      expect(result, 0);
    });

    test('is zero for an empty history', () {
      expect(SimulatedRealizedResultCalculator.total(const []), 0);
    });

    test('books the gain of a position bought and then sold in full', () {
      // 10 @ 48.09 -> 10 @ 49.59 = +15.00, the exact trade that vanished.
      final result = SimulatedRealizedResultCalculator.total([
        order('PETR4', SimulatedOrderSide.buy, 10, 48.09),
        order('PETR4', SimulatedOrderSide.sell, 10, 49.59),
      ]);

      expect(result, closeTo(15.0, 0.001));
    });

    test('books a loss as a negative number rather than dropping it', () {
      final result = SimulatedRealizedResultCalculator.total([
        order('VALE3', SimulatedOrderSide.buy, 5, 80),
        order('VALE3', SimulatedOrderSide.sell, 5, 71.6),
      ]);

      expect(result, closeTo(-42.0, 0.001));
    });

    test('charges a partial sale against the weighted-average cost, not the last buy', () {
      // 10 @ 10 and 10 @ 20 -> average 15. Selling 10 @ 18 books +30,
      // never the -20 a last-in-first-out reading would produce.
      final result = SimulatedRealizedResultCalculator.total([
        order('ABCD3', SimulatedOrderSide.buy, 10, 10),
        order('ABCD3', SimulatedOrderSide.buy, 10, 20),
        order('ABCD3', SimulatedOrderSide.sell, 10, 18),
      ]);

      expect(result, closeTo(30.0, 0.001));
    });

    test('keeps each ticker on its own books', () {
      final result = SimulatedRealizedResultCalculator.total([
        order('PETR4', SimulatedOrderSide.buy, 10, 48.09),
        order('VALE3', SimulatedOrderSide.buy, 5, 80),
        order('PETR4', SimulatedOrderSide.sell, 10, 49.59),
        order('VALE3', SimulatedOrderSide.sell, 5, 71.6),
      ]);

      expect(result, closeTo(15.0 - 42.0, 0.001));
    });

    test('reads the history in execution order, not the order it arrives in', () {
      final buy = order('PETR4', SimulatedOrderSide.buy, 10, 48.09, at: DateTime(2026, 1, 5));
      final sell = order('PETR4', SimulatedOrderSide.sell, 10, 49.59, at: DateTime(2026, 2, 5));

      expect(SimulatedRealizedResultCalculator.total([sell, buy]), closeTo(15.0, 0.001));
    });

    test('ignores a sell with no matching buy instead of inventing a cost of zero', () {
      // The backend rejects these, so one can only reach us through a
      // reset/import seam — booking it at a zero cost basis would report a
      // fictional profit equal to the whole sale.
      final result = SimulatedRealizedResultCalculator.total([order('PETR4', SimulatedOrderSide.sell, 10, 49.59)]);

      expect(result, 0);
    });

    test('reports per-ticker results so a closed position can be named', () {
      final byTicker = SimulatedRealizedResultCalculator.byTicker([
        order('PETR4', SimulatedOrderSide.buy, 10, 48.09),
        order('PETR4', SimulatedOrderSide.sell, 10, 49.59),
        order('VALE3', SimulatedOrderSide.buy, 5, 80),
      ]);

      expect(byTicker.keys, ['PETR4']);
      expect(byTicker['PETR4'], closeTo(15.0, 0.001));
    });
  });
}
