import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_order.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_order_side.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_portfolio_summary.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_position.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_position_quote.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/services/simulated_lot_builder.dart';

SimulatedPosition _position({
  String ticker = 'PETR4',
  double quantity = 10,
  double averagePrice = 30,
  double costBasis = 300,
}) {
  return SimulatedPosition(
    ticker: ticker,
    quantity: quantity,
    averagePrice: averagePrice,
    costBasis: costBasis,
    allocationPercent: 100,
  );
}

SimulatedOrder _order({
  required String ticker,
  SimulatedOrderSide side = SimulatedOrderSide.buy,
  required DateTime executedAt,
}) {
  return SimulatedOrder(
    id: 1,
    ticker: ticker,
    side: side,
    quantity: 10,
    price: 30,
    total: 300,
    executedAt: executedAt,
    clientOrderId: 'x',
  );
}

void main() {
  InvestmentTypeEnum stocksType(String ticker) => InvestmentTypeEnum.STOCKS;

  group('SimulatedLotBuilder.build', () {
    test('one lot per held position, using its net quantity/average price and a fetched current price', () {
      final portfolio = SimulatedPortfolioSummary(
        currency: 'BRL',
        resetAt: null,
        positions: [_position(quantity: 10, averagePrice: 30, costBasis: 300)],
      );
      final quotes = [SimulatedPositionQuote(position: portfolio.positions.single, currentPrice: 35)];

      final lots = SimulatedLotBuilder.build(
        portfolio: portfolio,
        quotes: quotes,
        orders: const [],
        typeOf: stocksType,
      );

      expect(lots.single.ticker, 'PETR4');
      expect(lots.single.quantity, 10);
      expect(lots.single.purchasePrice, 30);
      expect(lots.single.currentPrice, 35);
      expect(lots.single.investedValue, 300);
      expect(lots.single.currentValue, 350);
      expect(lots.single.priceStatus, PriceStatus.live);
      expect(lots.single.type, InvestmentTypeEnum.STOCKS);
    });

    test('uses the earliest BUY order for that ticker as the purchase date, ignoring later buys and sells', () {
      final portfolio = SimulatedPortfolioSummary(currency: 'BRL', resetAt: null, positions: [_position()]);
      final orders = [
        _order(ticker: 'PETR4', executedAt: DateTime(2025, 3, 1)),
        _order(ticker: 'PETR4', side: SimulatedOrderSide.sell, executedAt: DateTime(2025, 6, 1)),
        _order(ticker: 'PETR4', executedAt: DateTime(2025, 9, 1)),
        // A different ticker's earlier order must never leak into PETR4's lot.
        _order(ticker: 'VALE3', executedAt: DateTime(2024, 1, 1)),
      ];

      final lots = SimulatedLotBuilder.build(
        portfolio: portfolio,
        quotes: const [],
        orders: orders,
        typeOf: stocksType,
      );

      expect(lots.single.purchaseDate, DateTime(2025, 3, 1));
    });

    test('falls back to the portfolio reset date when there is no matching buy order', () {
      final resetAt = DateTime(2025, 1, 15);
      final portfolio = SimulatedPortfolioSummary(currency: 'BRL', resetAt: resetAt, positions: [_position()]);

      final lots = SimulatedLotBuilder.build(
        portfolio: portfolio,
        quotes: const [],
        orders: const [],
        typeOf: stocksType,
      );

      expect(lots.single.purchaseDate, resetAt);
    });

    test('a position with no fetched quote falls back to its cost basis, marked as not live', () {
      final portfolio = SimulatedPortfolioSummary(
        currency: 'BRL',
        resetAt: null,
        positions: [_position(quantity: 10, averagePrice: 30, costBasis: 300)],
      );

      final lots = SimulatedLotBuilder.build(
        portfolio: portfolio,
        quotes: const [],
        orders: const [],
        typeOf: stocksType,
      );

      expect(lots.single.currentPrice, 30);
      expect(lots.single.currentValue, 300);
      expect(lots.single.priceStatus, PriceStatus.stalePurchasePrice);
    });

    test('an empty portfolio builds no lots', () {
      final lots = SimulatedLotBuilder.build(
        portfolio: SimulatedPortfolioSummary.empty,
        quotes: const [],
        orders: const [],
        typeOf: stocksType,
      );

      expect(lots, isEmpty);
    });

    test('uses the caller-supplied type resolver per ticker', () {
      final portfolio = SimulatedPortfolioSummary(
        currency: 'BRL',
        resetAt: null,
        positions: [_position(ticker: 'HGLG11')],
      );

      final lots = SimulatedLotBuilder.build(
        portfolio: portfolio,
        quotes: const [],
        orders: const [],
        typeOf: (ticker) => ticker == 'HGLG11' ? InvestmentTypeEnum.REAL_ESTATE : InvestmentTypeEnum.OTHERS,
      );

      expect(lots.single.type, InvestmentTypeEnum.REAL_ESTATE);
    });
  });
}
