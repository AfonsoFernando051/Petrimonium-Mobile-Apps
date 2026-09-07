import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:petrimonium/core/theme/app_theme.dart';
import 'package:petrimonium/features/investment/data/models/investment_type_enum.dart';
import 'package:petrimonium/features/portfolio/domain/entities/allocation_slice.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/allocation_donut_card.dart';

void main() {
  Widget buildTestableWidget({required List<AllocationSlice> allocation, double totalValue = 0}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: AllocationDonutCard(allocation: allocation, totalValue: totalValue),
      ),
    );
  }

  group('AllocationDonutCard', () {
    testWidgets('shows a not-enough-data message and no chart when allocation is empty', (tester) async {
      await tester.pumpWidget(buildTestableWidget(allocation: const []));
      await tester.pump();

      expect(find.text('Alocação por Categoria'), findsOneWidget);
      expect(find.text('Sem dados suficientes para calcular sua alocação.'), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
    });

    testWidgets('renders a pie chart, the total value and one legend entry per slice', (tester) async {
      const allocation = [
        AllocationSlice(type: InvestmentTypeEnum.STOCKS, currentValue: 6000, portfolioPercent: 60),
        AllocationSlice(type: InvestmentTypeEnum.FIXED_INCOME, currentValue: 4000, portfolioPercent: 40),
      ];

      await tester.pumpWidget(buildTestableWidget(allocation: allocation, totalValue: 10000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(PieChart), findsOneWidget);
      expect(find.textContaining('R\$'), findsOneWidget);
      expect(find.text('Ações · 60%'), findsOneWidget);
      expect(find.text('R. Fixa · 40%'), findsOneWidget);
    });
  });
}
