import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/core/theme/app_theme.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/game_button.dart';
import 'package:petrimonium/features/onboarding/data/repositories/onboarding_state_repository.dart';
import 'package:petrimonium/features/onboarding/presentation/screens/mentor_welcome_screen.dart';
import 'package:petrimonium/features/onboarding/presentation/screens/quick_setup_screen.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});
    DI.onboardingStateRepository = OnboardingStateRepository();
  });

  Widget buildThemedTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: const MentorWelcomeScreen(),
    );
  }

  group('MentorWelcomeScreen', () {
    testWidgets('renders the Mentor card headline, paragraphs and CTA', (tester) async {
      await tester.pumpWidget(buildThemedTestableWidget());
      await tester.pump();

      expect(find.text('Mentor'), findsOneWidget);
      expect(find.text('Aqui é sobre o seu patrimônio real.'), findsOneWidget);
      expect(
        find.text(
          'Na Academy você aprendeu. Aqui você organiza, acompanha e entende seu dinheiro de verdade.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Os dados dependem da atualização do mercado — sempre com data e hora visíveis.'),
        findsOneWidget,
      );
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('tapping Continuar marks the welcome seen and navigates to QuickSetupScreen', (tester) async {
      await tester.pumpWidget(buildThemedTestableWidget());
      await tester.pump();

      expect(await DI.onboardingStateRepository.hasSeenMentorWelcome(), isFalse);

      await tester.tap(find.byType(GameButton), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(QuickSetupScreen), findsOneWidget);
      expect(await DI.onboardingStateRepository.hasSeenMentorWelcome(), isTrue);
    });
  });
}
