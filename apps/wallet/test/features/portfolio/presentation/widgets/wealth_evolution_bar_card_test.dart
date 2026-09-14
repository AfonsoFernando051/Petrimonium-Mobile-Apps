import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/portfolio/domain/services/monthly_wealth_series.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/wealth_evolution_bar_card.dart';

MonthlyWealthPoint month(int month, {required double invested, required double value}) =>
    MonthlyWealthPoint(month: DateTime(2026, month, 1), investedCapital: invested, portfolioValue: value);

void main() {
  setUp(() => Translator.currentLanguage = 'pt');

  Widget buildTestableWidget(List<MonthlyWealthPoint> series) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: WealthEvolutionBarCard(series: series)),
    );
  }

  group('WealthEvolutionBarCard', () {
    testWidgets('shows the title, the window chip and both legend entries', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget([month(8, invested: 100, value: 120), month(9, invested: 100, value: 140)]),
      );
      await tester.pump();

      expect(find.text('Evolução do patrimônio'), findsOneWidget);
      expect(find.text('12 meses'), findsOneWidget);
      expect(find.text('Valor aplicado'), findsOneWidget);
      expect(find.text('Ganho de capital'), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('shows an empty-state message and no chart with no history', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const []));
      await tester.pump();

      expect(find.byType(BarChart), findsNothing);
      expect(find.text('Ainda não há histórico suficiente para montar esse gráfico.'), findsOneWidget);
    });

    testWidgets('only names the shortfall segment when some month is actually underwater', (tester) async {
      await tester.pumpWidget(buildTestableWidget([month(9, invested: 100, value: 140)]));
      await tester.pump();
      expect(find.text('Abaixo do aplicado'), findsNothing);

      await tester.pumpWidget(buildTestableWidget([month(9, invested: 100, value: 80)]));
      await tester.pump();
      expect(find.text('Abaixo do aplicado'), findsOneWidget);
    });

    testWidgets('stacks invested capital under the capital gain', (tester) async {
      await tester.pumpWidget(buildTestableWidget([month(9, invested: 100, value: 140)]));
      await tester.pump();

      final chart = tester.widget<BarChart>(find.byType(BarChart));
      final rod = chart.data.barGroups.single.barRods.single;
      expect(rod.toY, 140);
      expect(rod.rodStackItems.first.fromY, 0);
      expect(rod.rodStackItems.first.toY, 100);
      expect(rod.rodStackItems.last.fromY, 100);
      expect(rod.rodStackItems.last.toY, 140);
    });

    testWidgets('an underwater month tops out at what was invested, not at the lower value', (tester) async {
      await tester.pumpWidget(buildTestableWidget([month(9, invested: 100, value: 80)]));
      await tester.pump();

      final chart = tester.widget<BarChart>(find.byType(BarChart));
      final rod = chart.data.barGroups.single.barRods.single;
      // The bar still reaches the invested line; the gap between the real
      // value and that line is the shortfall segment.
      expect(rod.toY, 100);
      expect(rod.rodStackItems.first.toY, 80);
      expect(rod.rodStackItems.last.fromY, 80);
      expect(rod.rodStackItems.last.toY, 100);
    });

    testWidgets('a dip is never painted in the error/alarm color', (tester) async {
      await tester.pumpWidget(buildTestableWidget([month(9, invested: 100, value: 80)]));
      await tester.pump();

      final chart = tester.widget<BarChart>(find.byType(BarChart));
      final shortfall = chart.data.barGroups.single.barRods.single.rodStackItems.last.color;
      expect(shortfall, isNot(AppTheme.dark.colorScheme.error));
    });
  });
}
