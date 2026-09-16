import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/home/presentation/widgets/portfolio_not_connected_card.dart';
import 'package:petrimonium_wallet/features/investment/presentation/screens/add_asset_screen.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/screens/carteira_screen.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/allocation_donut_card.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/holdings_section.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/wealth_evolution_bar_card.dart';

import '../controllers/portfolio_controller_test.dart';
import 'package:petrimonium_shared_features/testing.dart';

/// Mirrors `overview_screen_test.dart`'s double — this screen only needs a
/// working `MascotController` for `PortfolioNotConnectedCard`'s pet hero,
/// not real persistence.
class FakeMascotRepository implements MascotRepository {
  @override
  Future<PetProfile> loadProfile() async => PetProfile(specie: PetSpecieEnum.CAT);

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
  late FakePortfolioRepository repository;
  late PortfolioController controller;
  late MascotController mascotController;

  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});
    repository = FakePortfolioRepository();
    controller = PortfolioController(repository: repository);
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
        body: CarteiraScreen(controller: controller, mascotController: mascotController),
      ),
    );
  }

  group('CarteiraScreen', () {
    testWidgets('shows PortfolioNotConnectedCard when there are no holdings', (tester) async {
      await controller.loadAll();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(PortfolioNotConnectedCard), findsOneWidget);
      expect(find.byType(HoldingsSection), findsNothing);
    });

    testWidgets('shows the patrimônio header, evolution chart, allocation and holdings when holdings exist', (
      tester,
    ) async {
      final holdings = [lot(ticker: 'PETR4', quantity: 100, purchasePrice: 10)];
      repository.holdingsToReturn = Holding.fromLots(holdings);
      repository.summaryToReturn = statsFromLots(holdings).summary;
      await controller.loadAll();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      expect(find.byType(PortfolioNotConnectedCard), findsNothing);
      expect(find.text('Carteira'), findsOneWidget);
      expect(find.text('PATRIMÔNIO TOTAL'), findsOneWidget);
      expect(find.byType(WealthEvolutionBarCard), findsOneWidget);
      expect(find.byType(AllocationDonutCard), findsOneWidget);
      expect(find.byType(HoldingsSection), findsOneWidget);
    });

    testWidgets('tapping "Adicionar" next to the header opens AddAssetScreen', (tester) async {
      final holdings = [lot(ticker: 'PETR4', quantity: 100, purchasePrice: 10)];
      repository.holdingsToReturn = Holding.fromLots(holdings);
      repository.summaryToReturn = statsFromLots(holdings).summary;
      await controller.loadAll();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      // Not pumpAndSettle(): AddAssetScreen kicks off a real (unmocked,
      // DI-backed) network call in initState to seed existing holdings —
      // bounded pumps only, same pattern as overview_screen_test.dart.
      await tester.tap(find.text('Adicionar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AddAssetScreen), findsOneWidget);
    });
  });
}
