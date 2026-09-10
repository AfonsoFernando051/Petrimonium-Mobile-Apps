import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/auth/data/repositories/auth_repository.dart';
import 'package:petrimonium_wallet/features/auth/presentation/widgets/login_card.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/onboarding/data/repositories/onboarding_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
    DI.authRepository = MockAuthRepository();
    DI.onboardingRepository = MockOnboardingRepository();
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(body: LoginCard()),
    );
  }

  group('LoginCard', () {
    testWidgets('renders the dog mascot, brand title, the Entrar/Criar Conta toggle and LoginForm by default', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('PETRIMONIUM WALLET'), findsOneWidget);
      // Em pt a aba do alternador e o botão primário partilham o rótulo
      // 'Entrar', por isso aqui não se espera um único widget.
      expect(find.text('Entrar'), findsWidgets);
      expect(find.text('Criar Conta'), findsOneWidget);
      expect(find.byType(LoginForm), findsOneWidget);
      expect(find.byType(SignupForm), findsNothing);
    });

    testWidgets('tapping Cadastro swaps in SignupForm; tapping Login swaps back', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.text('Criar Conta'));
      await tester.pump();

      expect(find.byType(SignupForm), findsOneWidget);
      expect(find.byType(LoginForm), findsNothing);

      await tester.tap(find.text('Entrar').first);
      await tester.pump();

      expect(find.byType(LoginForm), findsOneWidget);
      expect(find.byType(SignupForm), findsNothing);
    });
  });
}
