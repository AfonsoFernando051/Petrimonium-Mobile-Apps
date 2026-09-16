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
    controller = PortfolioController(repository: portfolioRepository);

    when(() => investmentRepository.searchQuotes(any())).thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(() => investmentRepository.fetchQuoteAtDate(any(), any())).thenAnswer((_) async => null);

    DI.portfolioRepository = portfolioRepository;
    DI.investmentRepository = investmentRepository;
  });

  tearDown(() {
    mascotController.dispose();
    controller.dispose();
  });

  // Wrapped in a SingleChildScrollView, matching how both real hosts
  // (OverviewScreen, CarteiraScreen) always render this card — the Início
  // variant's companion bubble + KPI placeholders make it taller than the
  // default 600px test viewport.
  Widget buildTestableWidget({PortfolioEmptyStateVariant variant = PortfolioEmptyStateVariant.home}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: PortfolioNotConnectedCard(
            mascotController: mascotController,
            controller: controller,
            variant: variant,
          ),
        ),
      ),
    );
  }

  group('PortfolioNotConnectedCard — Início (home) variant', () {
    testWidgets('renders the companion badge/caption, title, body, KPI placeholders and both connect CTAs', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('COMPANION'), findsOneWidget);
      expect(
        find.text(
          'Sua jornada começa pela carteira. Adicione seu primeiro investimento e eu te acompanho a partir daí.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sua jornada começa pela carteira'), findsOneWidget);
      expect(
        find.text('Adicione seu primeiro investimento para acompanhar como seu patrimônio evolui.'),
        findsOneWidget,
      );
      expect(find.text('Patrimônio'), findsOneWidget);
      expect(find.text('Rentabilidade'), findsOneWidget);
      expect(find.text('Proventos'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Adicionar primeiro investimento'), findsOneWidget);
      expect(find.text('Conectar com a B3'), findsOneWidget);
      expect(find.text('EM BREVE'), findsOneWidget);
    });

    testWidgets('tapping the CTA navigates to AddAssetScreen', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.ensureVisible(find.byType(GameButton));
      await tester.pump();
      await tester.tap(find.byType(GameButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(AddAssetScreen), findsOneWidget);
    });

    testWidgets('tapping the B3 row shows a coming-soon snack instead of navigating', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.ensureVisible(find.text('Conectar com a B3'));
      await tester.pump();
      await tester.tap(find.text('Conectar com a B3'));
      await tester.pump();

      expect(find.byType(AddAssetScreen), findsNothing);
      expect(find.text('Em construção — em breve!'), findsOneWidget);
    });
  });

  group('PortfolioNotConnectedCard — Carteira variant', () {
    testWidgets('has its own simpler title/body, no companion badge and no KPI placeholders', (tester) async {
      await tester.pumpWidget(buildTestableWidget(variant: PortfolioEmptyStateVariant.carteira));
      await tester.pump();

      expect(find.text('Monte sua carteira'), findsOneWidget);
      expect(
        find.text('Adicione seus investimentos para acompanhar patrimônio, rentabilidade e proventos em um só lugar.'),
        findsOneWidget,
      );
      expect(find.text('COMPANION'), findsNothing);
      expect(find.text('Insights'), findsNothing);
      // The CTA into AddAssetScreen and the B3 row are still shared.
      expect(find.text('Adicionar primeiro investimento'), findsOneWidget);
      expect(find.text('Conectar com a B3'), findsOneWidget);
    });
  });
}
