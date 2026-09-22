import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/di/dependency_injection.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/academy/data/datasources/academy_remote_datasource.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/features/academy/presentation/screens/academy_domain_detail_screen.dart';
import 'package:petrimonium_academy/features/academy/presentation/screens/all_modules_screen.dart';
import 'package:petrimonium_academy/features/academy/presentation/screens/financial_lab/financial_lab_home_screen.dart';
import 'package:petrimonium_academy/features/academy/presentation/screens/academy_home_screen.dart';
import 'package:petrimonium_academy/features/academy/presentation/screens/lesson_screen.dart';
import 'package:petrimonium_academy/features/academy/presentation/screens/module_detail_screen.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/pet_companion_controller.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../academy_test_fixtures.dart';

class MockAcademyCatalogRepository extends Mock implements AcademyCatalogRepository {}

class MockAcademyRemoteDataSource extends Mock implements AcademyRemoteDataSource {}

/// Minimal in-memory MascotRepository double — mirrors the one in
/// `mascot_controller_test.dart`; these tests only need a working
/// `MascotController`, not real persistence.
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
  late MockAcademyCatalogRepository mockCatalogRepository;
  late MockAcademyRemoteDataSource mockRemoteDataSource;
  late MascotController mascotController;
  late PetCompanionController companionController;

  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});

    DI.academyProgressRepository = AcademyProgressLocalRepository();

    mockCatalogRepository = MockAcademyCatalogRepository();
    when(() => mockCatalogRepository.loadCached(any())).thenAnswer((_) async => buildAcademyCatalogSnapshot());
    when(() => mockCatalogRepository.fetchAndCache(any())).thenAnswer((_) async => buildAcademyCatalogSnapshot());
    DI.academyCatalogRepository = mockCatalogRepository;

    mockRemoteDataSource = MockAcademyRemoteDataSource();
    when(() => mockRemoteDataSource.getCompletedLessonIds()).thenAnswer((_) async => {});
    DI.academyRemoteDataSource = mockRemoteDataSource;

    mascotController = MascotController(repository: FakeMascotRepository());
    companionController = PetCompanionController(mascotController: mascotController);
  });

  Widget buildTestable({ThemeData? theme, double textScale = 1.0}) {
    return MaterialApp(
      theme: theme ?? AppTheme.dark,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: AcademyHomeScreen(
              mascotController: mascotController,
              companionController: companionController,
              onOpenPortfolioTab: () {},
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpUntilLoaded(WidgetTester tester) async {
    // Never pumpAndSettle — this screen has no CosmicBackground of its own
    // (it's embedded in DashboardScreen's shared one), but the companion
    // nudge/mascot Timer below is its own indefinitely-recurring source, so
    // the same rule applies. Several plain pumps flush the controller's
    // async load() chain (progress load -> catalog cache -> remote merge).
    for (var i = 0; i < 8; i++) {
      await tester.pump();
    }
    // The companion nudge (once a next lesson/review is known) and
    // MascotController's reactive animation each start their own Timer (up
    // to 9s) — flush it now so it doesn't outlive the test as a pending
    // timer (mascot/companion controllers are owned by the test, not the
    // screen, so nothing else cancels them).
    await tester.pump(const Duration(seconds: 10));
  }

  Future<void> tapAt(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await pumpUntilLoaded(tester);
  }

  group('AcademyHomeScreen journey', () {
    testWidgets('renders the journey: chapter, stage and the stage the learner is on', (tester) async {
      await tester.pumpWidget(buildTestable());
      await pumpUntilLoaded(tester);

      expect(find.text(Translator.translate(AppStrings.navAcademy)), findsOneWidget);
      expect(find.text(testDomain.title.toUpperCase()), findsOneWidget); // chapter heading
      expect(find.text(testSchool.title), findsOneWidget); // stage
      expect(find.text(testComingSoonSchool.title), findsOneWidget); // placeholder stage, not hidden
      expect(find.text(Translator.translate(AppStrings.academyJourneyYouAreHere).toUpperCase()), findsOneWidget);
    });

    testWidgets('unfolds the current stage down to its modules and lessons without a tap', (tester) async {
      await tester.pumpWidget(buildTestable());
      await pumpUntilLoaded(tester);

      expect(find.text(testModule.title), findsOneWidget);
      expect(find.text(testLesson1.title), findsOneWidget);
      expect(find.text(testLesson3.title), findsOneWidget);
    });

    testWidgets('collapsing the current stage hides its lessons and keeps the stage itself', (tester) async {
      await tester.pumpWidget(buildTestable());
      await pumpUntilLoaded(tester);

      await tapAt(tester, find.text(testSchool.title));

      expect(find.text(testSchool.title), findsOneWidget);
      expect(find.text(testLesson1.title), findsNothing);
      expect(find.text(testModule.title), findsNothing);
    });

    testWidgets('the continue CTA opens the real next lesson', (tester) async {
      await tester.pumpWidget(buildTestable());
      await pumpUntilLoaded(tester);

      await tapAt(tester, find.text(Translator.translate(AppStrings.academyJourneyContinueLesson)));

      expect(find.byType(LessonScreen), findsOneWidget);
      // `Explain` is testLesson1's first step — proof the CTA opened the
      // real next lesson, not just some lesson.
      expect(find.text('Explain'), findsOneWidget);
    });

    testWidgets('a module row opens ModuleDetailScreen', (tester) async {
      await tester.pumpWidget(buildTestable());
      await pumpUntilLoaded(tester);

      await tapAt(tester, find.text(testModule.title));

      expect(find.byType(ModuleDetailScreen), findsOneWidget);
    });

    testWidgets('the chapter heading still opens the domain it names', (tester) async {
      await tester.pumpWidget(buildTestable());
      await pumpUntilLoaded(tester);

      await tapAt(tester, find.text(testDomain.title.toUpperCase()));

      expect(find.byType(AcademyDomainDetailScreen), findsOneWidget);
    });

    testWidgets('the header action opens the full track', (tester) async {
      await tester.pumpWidget(buildTestable());
      await pumpUntilLoaded(tester);

      await tapAt(tester, find.byIcon(Icons.format_list_bulleted_rounded));

      expect(find.byType(AllModulesScreen), findsOneWidget);
    });

    testWidgets('holds up in light theme, on a small viewport and at large text', (tester) async {
      // The timeline is the one screen where a stage header, a progress bar,
      // a badge and the Pet share a single 390pt-wide row — the combination
      // that overflows first. Anything that does would surface here as a
      // framework exception rather than in a screenshot nobody took.
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestable(theme: AppTheme.light, textScale: 1.6));
      await pumpUntilLoaded(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(testSchool.title), findsOneWidget);
      expect(find.text(Translator.translate(AppStrings.academyJourneyContinueLesson)), findsOneWidget);
    });

    testWidgets('practice stays reachable from inside the journey', (tester) async {
      await tester.pumpWidget(buildTestable());
      await pumpUntilLoaded(tester);

      await tapAt(tester, find.byIcon(Icons.science_outlined));

      expect(find.byType(FinancialLabHomeScreen), findsOneWidget);
    });
  });
}
