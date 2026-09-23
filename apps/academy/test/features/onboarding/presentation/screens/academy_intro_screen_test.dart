import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium_academy/core/di/dependency_injection.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/academy/data/datasources/academy_remote_datasource.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/features/onboarding/presentation/onboarding_constants.dart';
import 'package:petrimonium_academy/features/onboarding/presentation/screens/academy_intro_screen.dart';
import 'package:petrimonium_academy/features/onboarding/presentation/screens/gamification_intro_screen.dart';
import 'package:petrimonium_academy/features/onboarding/presentation/screens/financial_goal_screen.dart';

class MockAcademyCatalogRepository extends Mock implements AcademyCatalogRepository {}

class MockAcademyRemoteDataSource extends Mock implements AcademyRemoteDataSource {}

/// Six schools — two past `kOnboardingTrackPreviewSchools` — so the cap and
/// the "mais N escolas" line are exercised over a catalog shaped like the
/// real one. `s1` is open from the start, `s2` is gated behind it, and each
/// school owns a module whose lessons are what its row counts.
final _snapshot = AcademyCatalogSnapshot(
  domains: const [],
  schools: [
    const School(
      id: 's1',
      title: 'Vida Financeira',
      description: 'desc',
      iconKey: 'savings_outlined',
      order: 1,
      contentAvailable: true,
    ),
    const School(
      id: 's2',
      title: 'Renda Fixa',
      description: 'desc',
      iconKey: 'shield_outlined',
      order: 2,
      prerequisites: ['s1'],
      contentAvailable: true,
    ),
    for (var i = 3; i <= 6; i++)
      School(
        id: 's$i',
        title: 'Escola $i',
        description: 'desc',
        iconKey: 'savings_outlined',
        order: i,
        contentAvailable: true,
      ),
  ],
  modules: [
    const AcademyModule(
      id: 'm1',
      schoolId: 's1',
      title: 'Fundamentos de Investimento',
      description: 'desc',
      iconKey: 'savings_outlined',
      order: 1,
      lessonIds: ['l1', 'l2', 'l3', 'l4'],
      contentAvailable: true,
    ),
    const AcademyModule(
      id: 'm2',
      schoolId: 's2',
      title: 'Renda Fixa Avancada',
      description: 'desc',
      iconKey: 'shield_outlined',
      order: 1,
      lessonIds: ['l5', 'l6', 'l7'],
      contentAvailable: true,
    ),
    for (var i = 3; i <= 6; i++)
      AcademyModule(
        id: 'm$i',
        schoolId: 's$i',
        title: 'Modulo $i',
        description: 'desc',
        iconKey: 'savings_outlined',
        order: 1,
        lessonIds: ['l$i-a'],
        contentAvailable: true,
      ),
  ],
  lessons: const [],
);

void main() {
  late MockAcademyCatalogRepository mockCatalogRepository;
  late MockAcademyRemoteDataSource mockRemoteDataSource;

  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});

    mockCatalogRepository = MockAcademyCatalogRepository();
    DI.academyCatalogRepository = mockCatalogRepository;
    when(() => mockCatalogRepository.loadCached(any())).thenAnswer((_) async => null);
    when(() => mockCatalogRepository.fetchAndCache(any())).thenAnswer((_) async => _snapshot);

    mockRemoteDataSource = MockAcademyRemoteDataSource();
    DI.academyRemoteDataSource = mockRemoteDataSource;
    // Best-effort background sync — keep it failing harmlessly so this
    // widget test never touches the real network.
    when(() => mockRemoteDataSource.getCompletedLessonIds()).thenThrow(Exception('offline'));
  });

  Widget buildTestableWidget() {
    return MaterialApp(theme: AppTheme.dark, home: const AcademyIntroScreen());
  }

  group('AcademyIntroScreen', () {
    testWidgets('renders the title and subtitle', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      // Hosts CosmicBackground + a pulsing GameButton (repeating
      // AnimationControllers) — never call pumpAndSettle.
      await tester.pump();
      await tester.pump();

      expect(find.text('Sua trilha começa aqui'), findsOneWidget);
      expect(find.text('Uma ordem sugerida — você escolhe por onde começar.'), findsOneWidget);
    });

    testWidgets('renders a track step per school, with real lesson counts and no fabricated claims', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      expect(find.text('Vida Financeira'), findsOneWidget);
      expect(find.text('Renda Fixa'), findsOneWidget);
      // s1 is the first reachable school → shows the "starts now" suffix,
      // over the lessons of every module it owns.
      expect(find.text('4 aulas · começa agora'), findsOneWidget);
      // s2 requires s1 (not completed) → locked → plain lesson count only.
      expect(find.text('3 aulas'), findsOneWidget);
    });

    testWidgets('shows only schools — never the modules underneath them', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      expect(find.text('Fundamentos de Investimento'), findsNothing);
      expect(find.text('Renda Fixa Avancada'), findsNothing);
    });

    testWidgets('caps the track at the preview count and sums up the schools left', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      expect(kOnboardingTrackPreviewSchools, 4);
      // 4 drawn (s1..s4), 2 folded into the summary line.
      expect(find.text('Escola 4'), findsOneWidget);
      expect(find.text('Escola 5'), findsNothing);
      expect(find.text('Escola 6'), findsNothing);
      expect(find.text('Mais 2 escolas na trilha.'), findsOneWidget);
    });

    testWidgets('renders the Mentor intro card naming the first school', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      expect(find.text('Vamos começar por Vida Financeira. 4 aulas — dá pra começar agora.'), findsOneWidget);
    });

    testWidgets('omits the track while the catalog has not loaded yet', (tester) async {
      final completer = Completer<AcademyCatalogSnapshot>();
      when(() => mockCatalogRepository.fetchAndCache(any())).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Vida Financeira'), findsNothing);

      // Resolve the pending future so it doesn't leak past the test.
      completer.complete(_snapshot);
      await tester.pump();
      await tester.pump();
    });

    testWidgets('tapping Next navigates to GamificationIntroScreen', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Próximo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(GamificationIntroScreen), findsOneWidget);
    });

    testWidgets('tapping Skip navigates to FinancialGoalScreen', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Pular'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(FinancialGoalScreen), findsOneWidget);
    });
  });
}
