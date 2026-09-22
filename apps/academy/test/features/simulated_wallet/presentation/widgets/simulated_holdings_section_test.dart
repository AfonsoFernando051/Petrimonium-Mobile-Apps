import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/simulated_holdings_section.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

Holding _holding({
  String ticker = 'PETR4',
  InvestmentTypeEnum type = InvestmentTypeEnum.STOCKS,
  double quantity = 10,
  double averagePrice = 30,
  double currentPrice = 30,
  double investedValue = 300,
  double currentValue = 300,
  double portfolioPercent = 100,
}) {
  return Holding(
    ticker: ticker,
    type: type,
    quantity: quantity,
    averagePrice: averagePrice,
    currentPrice: currentPrice,
    investedValue: investedValue,
    currentValue: currentValue,
    portfolioPercent: portfolioPercent,
    lots: [
      InvestmentLot(
        id: 0,
        ticker: ticker,
        type: type,
        quantity: quantity,
        purchasePrice: averagePrice,
        purchaseDate: DateTime(2024, 1, 1),
        currentPrice: currentPrice,
        investedValue: investedValue,
        currentValue: currentValue,
        priceStatus: PriceStatus.live,
      ),
    ],
  );
}

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  Widget buildTestableWidget(List<Holding> holdings, {double totalPortfolioValue = 0}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SimulatedHoldingsSection(holdings: holdings, totalPortfolioValue: totalPortfolioValue),
      ),
    );
  }

  group('SimulatedHoldingsSection', () {
    testWidgets('shows the empty state when there are no holdings', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const []));

      expect(
        find.text('Você ainda não tem posições simuladas. Que tal registrar sua primeira operação?'),
        findsOneWidget,
      );
    });

    testWidgets('groups holdings by type into one expandable category each', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget([
          _holding(ticker: 'PETR4', type: InvestmentTypeEnum.STOCKS, currentValue: 700, portfolioPercent: 70),
          _holding(ticker: 'HGLG11', type: InvestmentTypeEnum.REAL_ESTATE, currentValue: 300, portfolioPercent: 30),
        ], totalPortfolioValue: 1000),
      );

      expect(find.text('Ações'), findsOneWidget);
      expect(find.text('Fundos Imobiliários'), findsOneWidget);
    });

    testWidgets('the largest category starts expanded, showing its ticker row', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget([
          _holding(ticker: 'PETR4', type: InvestmentTypeEnum.STOCKS, currentValue: 700, portfolioPercent: 70),
        ], totalPortfolioValue: 700),
      );

      expect(find.text('PETR4'), findsOneWidget);
    });

    testWidgets('a live-quoted holding shows a performance badge with its signed gain percent', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget([
          _holding(currentValue: 350, investedValue: 300, currentPrice: 35, portfolioPercent: 100),
        ], totalPortfolioValue: 350),
      );

      expect(find.textContaining('16,67%'), findsWidgets);
    });

    testWidgets('a holding priced at a stale purchase price shows "sem cotação", not a fake 0%', (tester) async {
      final holding = Holding(
        ticker: 'VALE3',
        type: InvestmentTypeEnum.STOCKS,
        quantity: 10,
        averagePrice: 30,
        currentPrice: 30,
        investedValue: 300,
        currentValue: 300,
        portfolioPercent: 100,
        lots: [
          InvestmentLot(
            id: 0,
            ticker: 'VALE3',
            type: InvestmentTypeEnum.STOCKS,
            quantity: 10,
            purchasePrice: 30,
            purchaseDate: DateTime(2024, 1, 1),
            currentPrice: 30,
            investedValue: 300,
            currentValue: 300,
            priceStatus: PriceStatus.stalePurchasePrice,
          ),
        ],
      );

      await tester.pumpWidget(buildTestableWidget([holding], totalPortfolioValue: 300));

      expect(find.text('SEM COTAÇÃO'), findsOneWidget);
    });
  });
}
