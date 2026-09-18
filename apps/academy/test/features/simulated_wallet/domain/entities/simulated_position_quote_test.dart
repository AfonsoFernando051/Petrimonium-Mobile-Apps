import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_position.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_position_quote.dart';

SimulatedPosition _position({double quantity = 10, double averagePrice = 30, double costBasis = 300}) {
  return SimulatedPosition(
    ticker: 'PETR4',
    quantity: quantity,
    averagePrice: averagePrice,
    costBasis: costBasis,
    allocationPercent: 100,
  );
}

void main() {
  group('SimulatedPositionQuote', () {
    test('with a current price, computes current value and profit off cost basis', () {
      final quote = SimulatedPositionQuote(position: _position(quantity: 10, costBasis: 300), currentPrice: 35);

      expect(quote.hasQuote, isTrue);
      expect(quote.currentValue, 350);
      expect(quote.valueOrCostBasis, 350);
      expect(quote.profit, 50);
      expect(quote.profitPercent, closeTo(16.666, 0.01));
    });

    test('a price below the average price yields a negative profit', () {
      final quote = SimulatedPositionQuote(position: _position(quantity: 10, costBasis: 300), currentPrice: 25);

      expect(quote.profit, -50);
      expect(quote.profitPercent, closeTo(-16.666, 0.01));
    });

    test('with no current price, falls back to cost basis and reports no profit rather than zero', () {
      final quote = SimulatedPositionQuote(position: _position(costBasis: 300), currentPrice: null);

      expect(quote.hasQuote, isFalse);
      expect(quote.currentValue, isNull);
      expect(quote.valueOrCostBasis, 300);
      expect(quote.profit, isNull);
      expect(quote.profitPercent, isNull);
    });

    test('a zero cost basis never divides by zero for profitPercent', () {
      final quote = SimulatedPositionQuote(position: _position(quantity: 0, costBasis: 0), currentPrice: 10);

      expect(quote.profitPercent, isNull);
    });
  });
}
