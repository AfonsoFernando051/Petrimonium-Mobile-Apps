import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/features/investment/data/repositories/investment_repository.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/home/presentation/widgets/portfolio_not_connected_card.dart';
import 'package:petrimonium_wallet/features/investment/presentation/screens/add_asset_screen.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/portfolio_controller.dart';

import '../../../portfolio/presentation/controllers/portfolio_controller_test.dart';

/// Minimal in-memory MascotRepository double — mirrors the one in
/// `overview_screen_test.dart`/`profile_screen_test.dart`; this card only
/// needs a working `MascotController` for its `HomePetHero`, not real
/// persistence.
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

class MockInvestmentRepository extends Mock implements InvestmentRepository {}

void main() {
  late MascotController mascotController;
  late FakePortfolioRepository portfolioRepository;
  late MockInvestmentRepository investmentRepository;
  late PortfolioController controller;

  setUp(() {
    Translator.currentLanguage = 'pt';
    mascotController = MascotController(repository: FakeMascotRepository());
    portfolioRepository = FakePortfolioRepository();
    investmentRepository = MockInvestmentRepository();
    controller = PortfolioController(
      repository: portfolioRepository,
      achievementsLocalRepository: FakeAchievementsLocalRepository(),
      achievementsRepository: FakeAchievementsRepository(),
      gamificationRepository: FakeGamificationRepository(),
      missionsRepository: FakeMissionsRepository(),
    );

    when(() => investmentRepository.searchQuotes(any())).thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(() => investmentRepository.fetchQuoteAtDate(any(), any())).thenAnswer((_) async => null);

    DI.portfolioRepository = portfolioRepository;
    DI.investmentRepository = investmentRepository;
  });

  tearDown(() {
    mascotController.dispose();
    controller.dispose();
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: PortfolioNotConnectedCard(mascotController: mascotController, controller: controller),
      ),
    );
  }

  group('PortfolioNotConnectedCard', () {
    testWidgets('renders the companion caption, title, body and both connect CTAs', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(
        find.text('Vamos montar sua carteira juntos? Cadastre seu primeiro ativo — leva menos de um minuto.'),
        findsOneWidget,
      );
      expect(find.text('Portfólio ainda não conectado'), findsOneWidget);
      expect(find.text('Conecte seus investimentos quando estiver pronto — sem pressa.'), findsOneWidget);
      expect(find.text('Cadastrar ativo manualmente'), findsOneWidget);
      expect(find.text('Conectar com a B3'), findsOneWidget);
      expect(find.text('EM BREVE'), findsOneWidget);
    });

    testWidgets('tapping the manual CTA navigates to AddAssetScreen', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.byType(GameButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(AddAssetScreen), findsOneWidget);
    });

    testWidgets('tapping the B3 row shows a coming-soon snack instead of navigating', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.text('Conectar com a B3'));
      await tester.pump();

      expect(find.byType(AddAssetScreen), findsNothing);
      expect(find.text('Em construção — em breve!'), findsOneWidget);
    });
  });
}
