import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium/core/theme/app_theme.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/features/home/presentation/screens/overview_screen.dart';
import 'package:petrimonium/features/home/presentation/widgets/portfolio_not_connected_card.dart';
import 'package:petrimonium/features/investment/presentation/screens/add_asset_screen.dart';
import 'package:petrimonium/features/portfolio/domain/entities/holding.dart';
import 'package:petrimonium/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/allocation_donut_card.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/holdings_section.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/wealth_evolution_card.dart';

import '../../../portfolio/presentation/controllers/portfolio_controller_test.dart';
import '../../../portfolio/domain/services/portfolio_test_fixtures.dart';

void main() {
  late FakePortfolioRepository repository;
  late PortfolioController controller;

  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});
    repository = FakePortfolioRepository();
    controller = PortfolioController(
      repository: repository,
      achievementsLocalRepository: FakeAchievementsLocalRepository(),
      achievementsRepository: FakeAchievementsRepository(),
      gamificationRepository: FakeGamificationRepository(),
      missionsRepository: FakeMissionsRepository(),
    );
  });

  tearDown(() => controller.dispose());

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: OverviewScreen(controller: controller, onOpenMentor: (_) {}),
      ),
    );
  }

  group('OverviewScreen', () {
    testWidgets('shows PortfolioNotConnectedCard when there are no holdings', (tester) async {
      await controller.loadAll();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(PortfolioNotConnectedCard), findsOneWidget);
      expect(find.byType(HoldingsSection), findsNothing);
    });

    testWidgets('shows the wealth hero, real change breakdown and holdings when holdings exist', (tester) async {
      // Purchased well before the 30-day window, no price movement — the
      // real breakdown is all zeros, not the old "coming soon" placeholder.
      final holdings = [lot(ticker: 'PETR4', quantity: 100, purchasePrice: 10)];
      repository.holdingsToReturn = Holding.fromLots(holdings);
      repository.summaryToReturn = statsFromLots(holdings).summary;
      await controller.loadAll();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      expect(find.byType(PortfolioNotConnectedCard), findsNothing);
      expect(find.text('Como está meu patrimônio?'), findsOneWidget);
      expect(find.text('O que mudou (últimos 30 dias)'), findsOneWidget);
      expect(find.text('Valorização'), findsOneWidget);
      expect(find.text('Aportes'), findsOneWidget);
      expect(find.text('Rendimentos'), findsOneWidget);
      expect(find.text('+R\$ 0,00'), findsNWidgets(3));
      expect(find.byType(HoldingsSection), findsOneWidget);
      expect(find.byType(AllocationDonutCard), findsOneWidget);
      expect(find.byType(WealthEvolutionCard), findsOneWidget);
    });

    testWidgets('tapping "Adicionar" next to Meus ativos opens AddAssetScreen', (tester) async {
      final holdings = [lot(ticker: 'PETR4', quantity: 100, purchasePrice: 10)];
      repository.holdingsToReturn = Holding.fromLots(holdings);
      repository.summaryToReturn = statsFromLots(holdings).summary;
      await controller.loadAll();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      // The button sits below the new chart cards, off the default test
      // viewport — scroll it into view first, same as other CTAs further
      // down a scrollable form elsewhere in this codebase.
      await tester.ensureVisible(find.text('Adicionar'));
      await tester.pump();

      // Not pumpAndSettle(): AddAssetScreen kicks off a real (unmocked,
      // DI-backed) network call in initState to seed existing holdings —
      // bounded pumps only, same pattern as main_test.dart.
      await tester.tap(find.text('Adicionar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AddAssetScreen), findsOneWidget);
    });

    testWidgets('shows the "Bem-vindo(a) de volta" greeting', (tester) async {
      await controller.loadAll();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Bem-vindo(a) de volta'), findsOneWidget);
    });
  });
}
