import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/home/presentation/widgets/portfolio_not_connected_card.dart';
import 'package:petrimonium_wallet/features/investment/presentation/screens/investment_configuration_screen.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/controllers/mascot_controller.dart';

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

void main() {
  late MascotController mascotController;

  setUp(() {
    Translator.currentLanguage = 'pt';
    mascotController = MascotController(repository: FakeMascotRepository());
  });

  tearDown(() => mascotController.dispose());

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: PortfolioNotConnectedCard(mascotController: mascotController)),
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

    testWidgets('tapping the manual CTA navigates to InvestmentConfigurationScreen', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.byType(GameButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(InvestmentConfigurationScreen), findsOneWidget);
    });

    testWidgets('tapping the B3 row shows a coming-soon snack instead of navigating', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.text('Conectar com a B3'));
      await tester.pump();

      expect(find.byType(InvestmentConfigurationScreen), findsNothing);
      expect(find.text('Em construção — em breve!'), findsOneWidget);
    });
  });
}
