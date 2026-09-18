import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/features/simulated_wallet/data/repositories/simulated_wallet_repository.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/controllers/simulated_wallet_controller.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/screens/simulated_wallet_screen.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/simulation_disclaimer_banner.dart';

import '../../data/repositories/simulated_wallet_repository_test.dart';

void main() {
  late FakeSimulatedWalletRemoteDataSource remoteDataSource;
  late SimulatedWalletController controller;

  setUp(() {
    remoteDataSource = FakeSimulatedWalletRemoteDataSource();
    controller = SimulatedWalletController(repository: SimulatedWalletRepository(remoteDataSource: remoteDataSource));
  });

  tearDown(() => controller.dispose());

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: SimulatedWalletScreen(controller: controller),
    );
  }

  group('SimulatedWalletScreen', () {
    testWidgets('shows a loading indicator before the initial load resolves', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });

    testWidgets('always shows the simulation disclaimer once loaded, on every load state', (tester) async {
      remoteDataSource.portfolioToReturn = {
        'virtualBalance': 10000.0,
        'initialBalance': 10000.0,
        'currency': 'BRL',
        'resetAt': null,
        'positions': <Map<String, dynamic>>[],
      };
      await controller.loadPortfolio();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(SimulationDisclaimerBanner), findsOneWidget);
      expect(find.text(Translator.translate(AppStrings.simulatedWalletDisclaimer)), findsOneWidget);
    });

    testWidgets('renders the virtual balance and simulated positions once loaded', (tester) async {
      remoteDataSource.portfolioToReturn = {
        'virtualBalance': 9695.00,
        'initialBalance': 10000.00,
        'currency': 'BRL',
        'resetAt': null,
        'positions': [
          {'ticker': 'PETR4', 'quantity': 10.0, 'averagePrice': 30.5, 'costBasis': 305.0, 'allocationPercent': 100.0},
        ],
      };
      await controller.loadPortfolio();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.textContaining('9.695,00'), findsOneWidget);
      // Appears twice once positions exist: once in the allocation donut's
      // legend, once in the holdings list below it.
      expect(find.text('PETR4'), findsWidgets);
      expect(find.byType(AppLoadingIndicator), findsNothing);
    });

    testWidgets('shows the total patrimony and the allocation donut once positions exist', (tester) async {
      remoteDataSource.portfolioToReturn = {
        'virtualBalance': 1000.0,
        'initialBalance': 10000.0,
        'currency': 'BRL',
        'resetAt': null,
        'positions': [
          {'ticker': 'PETR4', 'quantity': 10.0, 'averagePrice': 30.0, 'costBasis': 300.0, 'allocationPercent': 100.0},
        ],
      };
      remoteDataSource.quoteToReturn = {'symbol': 'PETR4', 'regularMarketPrice': 35.0, 'currency': 'BRL'};
      await controller.loadPortfolio();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Patrimônio total: 1000 cash + 350 current value = 1350.
      expect(find.textContaining('1.350,00'), findsOneWidget);
      expect(find.text(Translator.translate(AppStrings.simulatedWalletAllocationTitle)), findsOneWidget);
      // Unrealized gain shown both on the KPI pill and the position row:
      // 350 - 300 = +50, +16.67%.
      expect(find.textContaining('+16.67%'), findsWidgets);
    });

    testWidgets('a losing position shows a negative signed result and return, not a fabricated gain', (tester) async {
      remoteDataSource.portfolioToReturn = {
        'virtualBalance': 0.0,
        'initialBalance': 10000.0,
        'currency': 'BRL',
        'resetAt': null,
        'positions': [
          {'ticker': 'VALE3', 'quantity': 10.0, 'averagePrice': 30.0, 'costBasis': 300.0, 'allocationPercent': 100.0},
        ],
      };
      remoteDataSource.quoteToReturn = {'symbol': 'VALE3', 'regularMarketPrice': 25.0, 'currency': 'BRL'};
      await controller.loadPortfolio();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // 250 current value - 300 cost basis = -50, -16.67%. Shown on both the
      // KPI pill and the position row.
      expect(find.textContaining('-R\$ 50,00'), findsWidgets);
      expect(find.textContaining('-16.67%'), findsWidgets);
    });

    testWidgets('shows no allocation donut and no KPI crash when there are no positions', (tester) async {
      remoteDataSource.portfolioToReturn = {
        'virtualBalance': 10000.0,
        'initialBalance': 10000.0,
        'currency': 'BRL',
        'resetAt': null,
        'positions': <Map<String, dynamic>>[],
      };
      await controller.loadPortfolio();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text(Translator.translate(AppStrings.simulatedWalletAllocationTitle)), findsNothing);
      expect(find.text(Translator.translate(AppStrings.simulatedWalletNoPositions)), findsOneWidget);
    });

    testWidgets('the FAB never labels itself as a real order', (tester) async {
      await controller.loadPortfolio();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      final fabLabel = Translator.translate(AppStrings.simulatedWalletNewOrderAction).toLowerCase();
      expect(fabLabel, isNot(contains('real')));
      expect(find.text(Translator.translate(AppStrings.simulatedWalletNewOrderAction)), findsOneWidget);
    });
  });
}
