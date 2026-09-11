import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:petrimonium_wallet/features/onboarding/data/repositories/onboarding_state_repository.dart';
import 'package:petrimonium_wallet/features/onboarding/presentation/screens/investor_profile_screen.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

class FakeOnboardingStateRepository implements OnboardingStateRepository {
  bool investorProfileSkipped = false;

  @override
  Future<void> markInvestorProfileSkipped() async {
    investorProfileSkipped = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockOnboardingRepository onboardingRepository;
  late FakeOnboardingStateRepository onboardingStateRepository;

  setUp(() {
    Translator.currentLanguage = 'pt';
    onboardingRepository = MockOnboardingRepository();
    when(
      () => onboardingRepository.submitAssessment(
        goal: any(named: 'goal'),
        investmentHorizon: any(named: 'investmentHorizon'),
        experienceLevel: any(named: 'experienceLevel'),
      ),
    ).thenAnswer((_) async => 'TACTICIAN');
    DI.onboardingRepository = onboardingRepository;

    onboardingStateRepository = FakeOnboardingStateRepository();
    DI.onboardingStateRepository = onboardingStateRepository;
  });

  Widget buildTestableWidget() {
    return MaterialApp(theme: AppTheme.dark, home: const InvestorProfileScreen());
  }

  group('InvestorProfileScreen', () {
    testWidgets('renders the title, subtitle, all three field labels and a disabled CTA', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Só mais um pouco de contexto'), findsOneWidget);
      expect(find.text('Qual é o seu objetivo agora?'), findsOneWidget);
      expect(find.text('Por quanto tempo pretende investir?'), findsOneWidget);
      expect(find.text('Qual sua experiência com investimentos?'), findsOneWidget);
      expect(find.text('Reserva de emergência'), findsOneWidget);
      expect(find.text('Até 1 ano'), findsOneWidget);
      expect(find.text('Nunca investi'), findsOneWidget);

      final button = tester.widget<GameButton>(find.byType(GameButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('the CTA enables only once all three fields are picked', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.ensureVisible(find.text('Reserva de emergência'));
      await tester.tap(find.text('Reserva de emergência'));
      await tester.pump();
      expect(tester.widget<GameButton>(find.byType(GameButton)).onPressed, isNull);

      await tester.ensureVisible(find.text('Até 1 ano'));
      await tester.tap(find.text('Até 1 ano'));
      await tester.pump();
      expect(tester.widget<GameButton>(find.byType(GameButton)).onPressed, isNull);

      await tester.ensureVisible(find.text('Nunca investi'));
      await tester.tap(find.text('Nunca investi'));
      await tester.pump();
      expect(tester.widget<GameButton>(find.byType(GameButton)).onPressed, isNotNull);
    });

    testWidgets('submitting sends the three wire-value answers to the backend', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.ensureVisible(find.text('Investir com mais confiança'));
      await tester.tap(find.text('Investir com mais confiança'));
      await tester.pump();
      await tester.ensureVisible(find.text('Mais de 5 anos'));
      await tester.tap(find.text('Mais de 5 anos'));
      await tester.pump();
      await tester.ensureVisible(find.text('Já invisto'));
      await tester.tap(find.text('Já invisto'));
      await tester.pump();

      await tester.ensureVisible(find.text('Concluir'));
      await tester.tap(find.byType(GameButton), warnIfMissed: false);
      await tester.pump();

      verify(
        () => onboardingRepository.submitAssessment(
          goal: 'INVEST_WITH_CONFIDENCE',
          investmentHorizon: 'MORE_THAN_FIVE_YEARS',
          experienceLevel: 'PRACTITIONER',
        ),
      ).called(1);
    });

    testWidgets('a submission failure shows a friendly error and never marks anything skipped', (tester) async {
      when(
        () => onboardingRepository.submitAssessment(
          goal: any(named: 'goal'),
          investmentHorizon: any(named: 'investmentHorizon'),
          experienceLevel: any(named: 'experienceLevel'),
        ),
      ).thenThrow(Exception('network down'));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.ensureVisible(find.text('Reserva de emergência'));
      await tester.tap(find.text('Reserva de emergência'));
      await tester.pump();
      await tester.ensureVisible(find.text('Até 1 ano'));
      await tester.tap(find.text('Até 1 ano'));
      await tester.pump();
      await tester.ensureVisible(find.text('Nunca investi'));
      await tester.tap(find.text('Nunca investi'));
      await tester.pump();

      await tester.ensureVisible(find.text('Concluir'));
      await tester.tap(find.byType(GameButton), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Não foi possível salvar suas respostas'), findsOneWidget);
      expect(find.byType(InvestorProfileScreen), findsOneWidget);
      expect(onboardingStateRepository.investorProfileSkipped, isFalse);
    });

    testWidgets('tapping "Pular" marks the step skipped without submitting anything', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.text('Pular'));
      await tester.pump();

      expect(onboardingStateRepository.investorProfileSkipped, isTrue);
      verifyNever(
        () => onboardingRepository.submitAssessment(
          goal: any(named: 'goal'),
          investmentHorizon: any(named: 'investmentHorizon'),
          experienceLevel: any(named: 'experienceLevel'),
        ),
      );
    });
  });
}
