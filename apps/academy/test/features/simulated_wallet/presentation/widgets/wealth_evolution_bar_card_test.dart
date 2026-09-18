import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/services/monthly_wealth_series.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/wealth_evolution_bar_card.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  Widget buildTestableWidget(List<MonthlyWealthPoint> series) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: WealthEvolutionBarCard(series: series)),
    );
  }

  group('WealthEvolutionBarCard', () {
    testWidgets('shows the empty message when there is no history yet', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const []));

      expect(find.text('Ainda não há histórico suficiente para montar esse gráfico.'), findsOneWidget);
    });

    testWidgets('shows the invested/gain legend, and the shortfall legend only when a month is underwater', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget([
          MonthlyWealthPoint(month: DateTime(2025, 1, 1), investedCapital: 100, portfolioValue: 120),
        ]),
      );
      expect(find.text('Valor aplicado'), findsOneWidget);
      expect(find.text('Ganho de capital'), findsOneWidget);
      expect(find.text('Abaixo do aplicado'), findsNothing);

      await tester.pumpWidget(
        buildTestableWidget([
          MonthlyWealthPoint(month: DateTime(2025, 1, 1), investedCapital: 100, portfolioValue: 80),
        ]),
      );
      expect(find.text('Abaixo do aplicado'), findsOneWidget);
    });
  });
}
