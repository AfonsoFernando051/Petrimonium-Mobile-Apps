import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_academy/features/simulated_wallet/data/repositories/simulated_wallet_repository.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/controllers/simulated_wallet_controller.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/screens/place_simulated_order_screen.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/screens/simulated_wallet_screen.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/simulated_portfolio_not_connected_card.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/simulation_disclaimer_banner.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/wealth_evolution_bar_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/simulated_wallet_repository_test.dart';

/// Minimal in-memory MascotRepository double — only `loadProfile` matters
/// for the screens under test here.
class FakeMascotRepository implements MascotRepository {
  @override
  Future<PetProfile> loadProfile() async => PetProfile();
  @override
  Future<void> saveName(String name) async {}
  @override
  Future<void> saveStage(PetEvolutionStage stage) async {}
  @override
  Future<void> saveXp(int xp) async {}
  @override
  Future<void> saveSpecie(PetSpecieEnum specie) async {}
  @override
  Future<void> saveNetWorth(double netWorth) async {}
  @override
  Future<void> saveEquippedAccessories(Map<AccessoryType, PetAccessoryId> equipped) async {}
  @override
  Future<void> saveUnlockedAccessories(Set<PetAccessoryId> unlocked) async {}
  @override
  Future<void> saveLastActiveAt(DateTime lastActiveAt) async {}
}

void main() {
  late FakeSimulatedWalletRemoteDataSource remoteDataSource;
  late SimulatedWalletController controller;
  late MascotController mascotController;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    remoteDataSource = FakeSimulatedWalletRemoteDataSource();
    controller = SimulatedWalletController(repository: SimulatedWalletRepository(remoteDataSource: remoteDataSource));
    mascotController = MascotController(repository: FakeMascotRepository());
  });

  tearDown(() {
    controller.dispose();
    mascotController.dispose();
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SimulatedWalletScreen(controller: controller, mascotController: mascotController),
      ),
    );
  }

  group('SimulatedWalletScreen', () {
    testWidgets('shows a loading indicator before the initial load resolves', (tester) async {
      // controller.isLoading starts true and positions empty by default —
      // the screen shows a full-screen loader in that state, before
      // loadPortfolio() is ever called (that's DashboardScreen's job, same
      // as PortfolioController.loadAll() — see HomeScreen's own loading test).
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });

    testWidgets('shows the title/subtitle header and the simulation disclaimer once loaded', (tester) async {
      remoteDataSource.portfolioToReturn = {'currency': 'BRL', 'resetAt': null, 'positions': <Map<String, dynamic>>[]};
      await controller.loadPortfolio();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text(Translator.translate(AppStrings.simulatedWalletTitle)), findsOneWidget);
      expect(find.text(Translator.translate(AppStrings.simulatedWalletHeaderSubtitle)), findsOneWidget);
      expect(find.byType(SimulationDisclaimerBanner), findsOneWidget);
      expect(find.text(Translator.translate(AppStrings.simulatedWalletDisclaimer)), findsOneWidget);
    });

    // Selling the last position used to return the wallet to its pristine
    // "Monte sua carteira simulada / Adicione seu primeiro ativo" state,
    // erasing the trade the student had just practised along with its
    // result. The history is the one place a closed position survives.
    group('after closing every position', () {
      void givenABoughtAndSoldPosition() {
        remoteDataSource.portfolioToReturn = {
          'currency': 'BRL',
          'resetAt': null,
          'positions': <Map<String, dynamic>>[],
        };
        remoteDataSource.ordersToReturn = [
          {
            'id': 1,
            'ticker': 'PETR4',
            'side': 'BUY',
            'quantity': 10.0,
            'price': 48.09,
            'total': 480.9,
            'executedAt': '2026-01-05T12:00:00Z',
            'clientOrderId': 'o1',
          },
          {
            'id': 2,
            'ticker': 'PETR4',
            'side': 'SELL',
            'quantity': 10.0,
            'price': 49.59,
            'total': 495.9,
            'executedAt': '2026-02-05T12:00:00Z',
            'clientOrderId': 'o2',
          },
        ];
      }

      testWidgets('does not pretend the student never started', (tester) async {
        givenABoughtAndSoldPosition();
        await controller.loadPortfolio();

        await tester.pumpWidget(buildTestableWidget());
        await tester.pump();

        expect(find.byType(SimulatedPortfolioNotConnectedCard), findsNothing);
        expect(find.text(Translator.translate(AppStrings.simulatedAllPositionsClosedTitle)), findsOneWidget);
      });

      testWidgets('still shows both orders, newest first', (tester) async {
        givenABoughtAndSoldPosition();
        await controller.loadPortfolio();

        await tester.pumpWidget(buildTestableWidget());
        await tester.pump();

        expect(find.text(Translator.translate(AppStrings.simulatedOrderHistoryTitle)), findsOneWidget);
        expect(find.textContaining('Compra · PETR4'), findsOneWidget);
        expect(find.textContaining('Venda · PETR4'), findsOneWidget);
      });

      testWidgets('reports the result the trade actually produced', (tester) async {
        givenABoughtAndSoldPosition();
        await controller.loadPortfolio();

        await tester.pumpWidget(buildTestableWidget());
        await tester.pump();

        expect(find.textContaining('R\$ 15,00'), findsWidgets);
      });
    });

    testWidgets('a wallet that has never traded still offers the first-asset card', (tester) async {
      remoteDataSource.portfolioToReturn = {'currency': 'BRL', 'resetAt': null, 'positions': <Map<String, dynamic>>[]};
      remoteDataSource.ordersToReturn = [];
      await controller.loadPortfolio();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(SimulatedPortfolioNotConnectedCard), findsOneWidget);
      expect(find.text(Translator.translate(AppStrings.simulatedOrderHistoryTitle)), findsNothing);
    });

    testWidgets('renders the positions the user added, with patrimony equal to their value and no cash on top', (
      tester,
    ) async {
      remoteDataSource.portfolioToReturn = {
        'currency': 'BRL',
        'resetAt': null,
        'positions': [
          {'ticker': 'PETR4', 'quantity': 10.0, 'averagePrice': 30.5, 'costBasis': 305.0, 'allocationPercent': 100.0},
        ],
      };
      await controller.loadPortfolio();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // No quote here, so the position is valued at its 305.00 cost basis — the whole patrimony.
      expect(find.textContaining('305,00'), findsWidgets);
      expect(find.textContaining('10.000,00'), findsNothing);
      // Grouped by type now (STOCKS/"Ações"), not by ticker — the ticker
      // itself only shows on its own row inside the expanded category.
      expect(find.text('PETR4'), findsOneWidget);
      expect(find.byType(AppLoadingIndicator), findsNothing);
    });

    testWidgets('shows the total patrimony, wealth chart and allocation donut once positions exist', (tester) async {
      remoteDataSource.portfolioToReturn = {
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

      // Patrimônio total is just the 350 current value — no cash is added on top.
      expect(find.textContaining('R\$ 350,00'), findsWidgets);
      expect(find.textContaining('1.350,00'), findsNothing);
      expect(find.text(Translator.translate(AppStrings.simulatedWalletAllocationTitle)), findsOneWidget);
      expect(find.byType(WealthEvolutionBarCard), findsOneWidget);
      // Unrealized gain shown on the KPI pill, the category header and the
      // asset row: 350 - 300 = +50, +16,67%.
      expect(find.textContaining('+16,67%'), findsWidgets);
    });

    testWidgets('a losing position shows a negative signed result and return, not a fabricated gain', (tester) async {
      remoteDataSource.portfolioToReturn = {
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

      // 250 current value - 300 cost basis = -50, -16,67%.
      expect(find.textContaining('-R\$ 50,00'), findsWidgets);
      expect(find.textContaining('-16,67%'), findsWidgets);
    });

    testWidgets(
      'shows the pet empty-state card inviting a first asset, hiding the wealth/allocation/holdings sections',
      (tester) async {
        remoteDataSource.portfolioToReturn = {
          'currency': 'BRL',
          'resetAt': null,
          'positions': <Map<String, dynamic>>[],
        };
        await controller.loadPortfolio();

        await tester.pumpWidget(buildTestableWidget());
        await tester.pump();

        expect(find.byType(SimulatedPortfolioNotConnectedCard), findsOneWidget);
        expect(find.text(Translator.translate(AppStrings.simulatedWalletEmptyStateTitle)), findsOneWidget);
        expect(find.text(Translator.translate(AppStrings.simulatedWalletEmptyStateCta)), findsOneWidget);
        expect(find.text(Translator.translate(AppStrings.simulatedWalletAllocationTitle)), findsNothing);
        expect(find.byType(WealthEvolutionBarCard), findsNothing);
      },
    );

    testWidgets('the empty-state CTA never labels itself as a real order, and opens the order screen', (tester) async {
      remoteDataSource.portfolioToReturn = {'currency': 'BRL', 'resetAt': null, 'positions': <Map<String, dynamic>>[]};
      await controller.loadPortfolio();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      final addLabel = Translator.translate(AppStrings.simulatedWalletEmptyStateCta);
      expect(addLabel.toLowerCase(), isNot(contains('real')));

      await tester.tap(find.text(addLabel));
      await tester.pumpAndSettle();

      expect(find.byType(PlaceSimulatedOrderScreen), findsOneWidget);
    });

    testWidgets('once a first asset exists, the full carteira replaces the empty-state card', (tester) async {
      remoteDataSource.portfolioToReturn = {
        'currency': 'BRL',
        'resetAt': null,
        'positions': [
          {'ticker': 'PETR4', 'quantity': 10.0, 'averagePrice': 30.5, 'costBasis': 305.0, 'allocationPercent': 100.0},
        ],
      };
      await controller.loadPortfolio();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(SimulatedPortfolioNotConnectedCard), findsNothing);
      expect(find.text(Translator.translate(AppStrings.simulatedWalletAddAssetLabel)), findsOneWidget);
    });

    testWidgets('the reset icon is present and disabled while a reset is in flight', (tester) async {
      remoteDataSource.portfolioToReturn = {'currency': 'BRL', 'resetAt': null, 'positions': <Map<String, dynamic>>[]};
      await controller.loadPortfolio();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byTooltip(Translator.translate(AppStrings.simulatedWalletResetAction)), findsOneWidget);
    });
  });
}
