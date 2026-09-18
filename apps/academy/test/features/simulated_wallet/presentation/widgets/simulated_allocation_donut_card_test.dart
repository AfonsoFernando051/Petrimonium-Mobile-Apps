import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/simulated_allocation_donut_card.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  Widget buildTestableWidget(List<AllocationSlice> allocation, {double totalValue = 0}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SimulatedAllocationDonutCard(allocation: allocation, totalValue: totalValue),
      ),
    );
  }

  group('SimulatedAllocationDonutCard', () {
    testWidgets('shows the empty message when there is no allocation yet', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const []));

      expect(find.text('Sem dados suficientes para calcular sua alocação.'), findsOneWidget);
    });

    testWidgets('shows one legend row per type, with its short label and rounded percent', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget([
          const AllocationSlice(type: InvestmentTypeEnum.STOCKS, currentValue: 700, portfolioPercent: 70),
          const AllocationSlice(type: InvestmentTypeEnum.REAL_ESTATE, currentValue: 300, portfolioPercent: 30),
        ], totalValue: 1000),
      );

      expect(find.text('Ações'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('FIIs'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
    });

    testWidgets('shows the total value in the donut hole', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget([
          const AllocationSlice(type: InvestmentTypeEnum.STOCKS, currentValue: 1000, portfolioPercent: 100),
        ], totalValue: 1000),
      );

      expect(find.textContaining('1.000'), findsOneWidget);
    });
  });
}
