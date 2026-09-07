import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium/core/theme/app_theme.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/game_button.dart';
import 'package:petrimonium/features/home/presentation/widgets/portfolio_not_connected_card.dart';
import 'package:petrimonium/features/investment/presentation/screens/investment_configuration_screen.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(body: PortfolioNotConnectedCard()),
    );
  }

  group('PortfolioNotConnectedCard', () {
    testWidgets('renders the title, body and connect CTA', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Portfólio ainda não conectado'), findsOneWidget);
      expect(find.text('Conecte seus investimentos quando estiver pronto — sem pressa.'), findsOneWidget);
      expect(find.text('Conectar Investimentos'), findsOneWidget);
    });

    testWidgets('tapping the connect CTA navigates to InvestmentConfigurationScreen', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.byType(GameButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(InvestmentConfigurationScreen), findsOneWidget);
    });
  });
}
