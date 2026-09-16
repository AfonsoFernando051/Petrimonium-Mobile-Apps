import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/auth/data/repositories/auth_repository.dart';
import 'package:petrimonium_wallet/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:petrimonium_wallet/features/onboarding/data/repositories/onboarding_state_repository.dart';
import 'package:petrimonium_wallet/features/onboarding/data/repositories/wallet_market_preferences_repository.dart';
import 'package:petrimonium_wallet/features/onboarding/presentation/screens/quick_setup_screen.dart';
import 'package:petrimonium_wallet/features/pet/domain/repositories/pet_repository.dart';

import '../../../../features/academy/academy_test_fixtures.dart';

// ── Doubles for the "completing onboarding lands on Dashboard" regression
// test below — deliberately left unstubbed for anything DashboardScreen
// doesn't itself need, so an accidental reintroduction of a network-backed
// re-resolve (the bug this guards against — see `_handleContinue`'s doc
// comment in quick_setup_screen.dart) fails loudly via mocktail's
// missing-stub error instead of silently passing.
class MockAuthRepository extends Mock implements AuthRepository {}

class MockPetRepository extends Mock implements PetRepository {}

class MockAcademyCatalogRepository extends Mock implements AcademyCatalogRepository {}

class FakeMascotRepository implements MascotRepository {
  @override
  Future<PetProfile> loadProfile() async => PetProfile(name: 'Rex', specie: PetSpecieEnum.CAT);

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

class FakePortfolioRepository implements PortfolioRepository {
  @override
  Future<List<Holding>> fetchHoldings() async => const [];

  @override
  Future<PortfolioSummary> fetchSummary() async => PortfolioSummary.empty;

  @override
  Future<List<AllocationSlice>> fetchAllocation() async => const [];

  @override
  Future<List<HistoryPoint>> fetchHistory(HistoryRange range) async => const [];

  @override
  Future<DividendRadar> fetchDividendRadar() async => DividendRadar.empty;

  @override
  PortfolioRemoteDataSource get remoteDataSource => throw UnimplementedError();
}

class FakeAchievementsLocalRepository implements AchievementsLocalRepository {
  @override
  Future<Map<String, DateTime>> loadUnlocked() async => {};

  @override
  Future<void> cacheUnlocked(Map<String, DateTime> unlockedAt) async {}
}

class FakeAchievementsRepository implements AchievementsRepository {
  @override
  Future<AchievementEvaluationResult> evaluate() async => AchievementEvaluationResult.empty;

  @override
  AchievementsRemoteDataSource get remoteDataSource => throw UnimplementedError();
}

class FakeGamificationRepository implements GamificationRepository {
  @override
  Future<GamificationSummary> fetchSummary() async => GamificationSummary.empty;

  @override
  GamificationRemoteDataSource get remoteDataSource => throw UnimplementedError();
}

class FakeMissionsRepository implements MissionsRepository {
  @override
  Future<MissionEvaluationResult> evaluate() async => MissionEvaluationResult.empty;

  @override
  MissionsRemoteDataSource get remoteDataSource => throw UnimplementedError();
}

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});
    DI.walletMarketPreferencesRepository = WalletMarketPreferencesRepository();
  });

  Widget buildThemedTestableWidget() {
    return MaterialApp(theme: AppTheme.dark, home: const QuickSetupScreen());
  }

  group('QuickSetupScreen', () {
    testWidgets('renders title, subtitle, field labels/values and footer note', (tester) async {
      await tester.pumpWidget(buildThemedTestableWidget());
      await tester.pump();

      expect(find.text('Antes de começar'), findsOneWidget);
      expect(find.text('Só o essencial — dá pra ajustar depois.'), findsOneWidget);
      expect(find.text('País / mercado'), findsOneWidget);
      // As opções ficam à vista em pastilhas, com a bandeira à parte do
      // rótulo — o artboard `PrefsWallet` não usa campo que abre folha.
      expect(find.text('Brasil · B3'), findsOneWidget);
      expect(find.text('🇧🇷'), findsOneWidget);
      expect(find.text('Moeda-base'), findsOneWidget);
      expect(find.text('BRL — Real'), findsOneWidget);
      expect(find.byType(OptionPill), findsNWidgets(2));
      expect(
        find.text(
          'Você vai adicionar seus ativos manualmente no próximo passo — nada é importado automaticamente ainda.',
        ),
        findsOneWidget,
      );
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('shows the choices inline and marks the current one, with no modal', (tester) async {
      // GameButton's CTA pulse animation repeats forever (see
      // welcome_screen_test.dart's comment on the same constraint) — explicit
      // pumps only, never pumpAndSettle, for the whole test.
      await tester.pumpWidget(buildThemedTestableWidget());
      await tester.pump();

      final marketPill = find.ancestor(of: find.text('Brasil · B3'), matching: find.byType(OptionPill));
      expect(tester.widget<OptionPill>(marketPill).selected, isTrue);

      await tester.tap(find.text('Brasil · B3'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Nada de folha modal: a escolha resolve-se no próprio ecrã.
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.widget<OptionPill>(marketPill).selected, isTrue);
    });

    testWidgets(
      'completing onboarding lands directly on DashboardScreen, without re-resolving auth/pet state over the network',
      (tester) async {
        // Regression test for the bug where finishing onboarding bounced the
        // user back to the login screen: `_handleContinue` used to restart
        // `MyApp()`, which re-ran `StartRouteResolver` (isLoggedIn/
        // getPetStatus) — any non-network hiccup there forced a logout.
        // `isLoggedIn`/`logout` and `getPetStatus`/`configurePet` are
        // deliberately left unstubbed: if `_handleContinue` ever calls any
        // of them again, mocktail's missing-stub error fails this test
        // immediately. Only the stubs DashboardScreen's own subtree
        // genuinely needs (MentorScreen's `getMyPet`, Home's greeting email)
        // are provided.
        final authRepository = MockAuthRepository();
        when(() => authRepository.getSavedEmail()).thenAnswer((_) async => null);
        DI.authRepository = authRepository;

        final petRepository = MockPetRepository();
        when(() => petRepository.getMyPet()).thenAnswer((_) async => null);
        DI.petRepository = petRepository;

        DI.mascotRepository = FakeMascotRepository();
        DI.onboardingStateRepository = OnboardingStateRepository();
        DI.portfolioRepository = FakePortfolioRepository();
        DI.achievementsLocalRepository = FakeAchievementsLocalRepository();
        DI.achievementsRepository = FakeAchievementsRepository();
        DI.gamificationRepository = FakeGamificationRepository();
        DI.missionsRepository = FakeMissionsRepository();
        DI.academyProgressRepository = AcademyProgressLocalRepository();

        final mockCatalogRepository = MockAcademyCatalogRepository();
        when(() => mockCatalogRepository.loadCached(any())).thenAnswer((_) async => buildAcademyCatalogSnapshot());
        when(() => mockCatalogRepository.fetchAndCache(any())).thenAnswer((_) async => buildAcademyCatalogSnapshot());
        DI.academyCatalogRepository = mockCatalogRepository;

        await tester.pumpWidget(buildThemedTestableWidget());
        await tester.pump();

        await tester.tap(find.text('Continuar'));
        for (var i = 0; i < 10; i++) {
          await tester.pump();
        }
        // Flushes the persistent companion's greeting Timer so it doesn't
        // outlive this test as a pending timer (same as main_test.dart).
        await tester.pump(const Duration(seconds: 10));

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.byType(QuickSetupScreen), findsNothing);
        expect(await DI.onboardingStateRepository.hasCompletedQuickSetup(), isTrue);
      },
    );
  });
}
