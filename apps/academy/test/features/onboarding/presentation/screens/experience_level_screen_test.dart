import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium_academy/core/di/dependency_injection.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:petrimonium_academy/features/onboarding/presentation/screens/experience_level_screen.dart';
import 'package:petrimonium_academy/features/onboarding/presentation/screens/journey_ready_screen.dart';
import 'package:petrimonium_academy/features/pet/data/models/experience_level_enum.dart';
import 'package:petrimonium_academy/features/pet/data/models/investment_horizon_enum.dart';
import 'package:petrimonium_academy/features/pet/data/models/pet_goal_enum.dart';
import 'package:petrimonium_academy/features/pet/data/repositories/pet_preferences_repository.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

/// Minimal in-memory MascotRepository double — further down the onboarding
/// chain, JourneyReadyScreen calls `loadProfile` in its own initState, and
/// the real DI default would hit the network for real in a widget test.
class FakeMascotRepository implements MascotRepository {
  PetProfile profileToReturn = PetProfile(name: 'Bolt');

  @override
  Future<PetProfile> loadProfile() async => profileToReturn;
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
  late MockOnboardingRepository mockOnboardingRepository;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});
    DI.petPreferencesRepository = PetPreferencesRepository();
    DI.mascotRepository = FakeMascotRepository();

    mockOnboardingRepository = MockOnboardingRepository();
    when(
      () => mockOnboardingRepository.submitAssessment(
        goal: any(named: 'goal'),
        investmentHorizon: any(named: 'investmentHorizon'),
        experienceLevel: any(named: 'experienceLevel'),
      ),
    ).thenAnswer((_) async => 'TACTICIAN');
    DI.onboardingRepository = mockOnboardingRepository;
  });

  Widget buildTestableWidget() {
    return MaterialApp(theme: AppTheme.dark, home: const ExperienceLevelScreen());
  }

  group('ExperienceLevelScreen', () {
    testWidgets('renders the title, subtitle and a row for every level', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      // Hosts CosmicBackground + a pulsing GameButton — never pumpAndSettle.
      await tester.pump();

      expect(find.text('Como está sua experiência hoje?'), findsOneWidget);
      expect(find.text('Assim a Academy não te ensina o que você já sabe.'), findsOneWidget);
      for (final level in ExperienceLevelEnum.values) {
        expect(find.text(level.label), findsOneWidget, reason: level.name);
        expect(find.text(level.description), findsOneWidget, reason: level.name);
      }
    });

    testWidgets('defaults to novice selected', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('tapping a level row selects it', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.text(ExperienceLevelEnum.practitioner.label));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('tapping Next saves the level and navigates to JourneyReadyScreen', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.text(ExperienceLevelEnum.curious.label));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Próximo'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(await DI.petPreferencesRepository.loadExperienceLevel(), ExperienceLevelEnum.curious);
      expect(find.byType(JourneyReadyScreen), findsOneWidget);
    });

    testWidgets('tapping Next submits the three real onboarding answers for investor-profile classification', (
      tester,
    ) async {
      // Goal/horizon were chosen on earlier onboarding screens; this
      // screen only knows/saves the experience level itself.
      await DI.petPreferencesRepository.saveGoal(PetGoalEnum.investWithConfidence);
      await DI.petPreferencesRepository.saveHorizon(InvestmentHorizonEnum.moreThanFiveYears);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.text(ExperienceLevelEnum.practitioner.label));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Próximo'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      verify(
        () => mockOnboardingRepository.submitAssessment(
          goal: 'INVEST_WITH_CONFIDENCE',
          investmentHorizon: 'MORE_THAN_FIVE_YEARS',
          experienceLevel: 'PRACTITIONER',
        ),
      ).called(1);
    });

    testWidgets('a failed submission never blocks navigation to JourneyReadyScreen', (tester) async {
      when(
        () => mockOnboardingRepository.submitAssessment(
          goal: any(named: 'goal'),
          investmentHorizon: any(named: 'investmentHorizon'),
          experienceLevel: any(named: 'experienceLevel'),
        ),
      ).thenThrow(Exception('network down'));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.text('Próximo'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(JourneyReadyScreen), findsOneWidget);
    });
  });
}
