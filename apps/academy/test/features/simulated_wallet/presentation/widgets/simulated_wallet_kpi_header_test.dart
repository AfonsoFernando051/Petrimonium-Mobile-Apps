import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/simulated_wallet_kpi_header.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  Widget buildTestableWidget({
    required double totalPatrimony,
    required double totalProfit,
    required double totalProfitPercent,
    required double virtualBalance,
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SimulatedWalletKpiHeader(
          totalPatrimony: totalPatrimony,
          totalProfit: totalProfit,
          totalProfitPercent: totalProfitPercent,
          virtualBalance: virtualBalance,
        ),
      ),
    );
  }

  group('SimulatedWalletKpiHeader', () {
    testWidgets('shows the total patrimony and cash balance', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(totalPatrimony: 1350, totalProfit: 50, totalProfitPercent: 16.67, virtualBalance: 1000),
      );

      expect(find.textContaining('1.350,00'), findsOneWidget);
      expect(find.textContaining('1.000,00'), findsOneWidget);
    });

    testWidgets('colors a gain green (success token), never the error color', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(totalPatrimony: 1350, totalProfit: 50, totalProfitPercent: 16.67, virtualBalance: 1000),
      );

      final resultText = tester.widget<Text>(find.textContaining('R\$ 50,00'));
      final tokens = AppTheme.dark.extension<AppColorTokens>()!;
      expect(resultText.style?.color, tokens.success);
    });

    testWidgets('colors a loss red (error token), with a signed negative currency and percent', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(totalPatrimony: 950, totalProfit: -50, totalProfitPercent: -16.67, virtualBalance: 1000),
      );

      final resultText = tester.widget<Text>(find.textContaining('-R\$ 50,00'));
      final tokens = AppTheme.dark.extension<AppColorTokens>()!;
      expect(resultText.style?.color, tokens.error);
      expect(find.textContaining('-16.67%'), findsOneWidget);
    });
  });
}
