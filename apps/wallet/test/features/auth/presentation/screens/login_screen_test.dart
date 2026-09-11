import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_wallet/features/auth/data/repositories/auth_repository.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:petrimonium_wallet/features/auth/presentation/screens/login_screen.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/features/auth/presentation/widgets/login_background.dart';
import 'package:petrimonium_wallet/features/auth/presentation/widgets/login_card.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockOnboardingRepository mockOnboardingRepository;

  setUp(() {
    Translator.currentLanguage = 'pt';
    mockAuthRepository = MockAuthRepository();
    DI.authRepository = mockAuthRepository;

    mockOnboardingRepository = MockOnboardingRepository();
    DI.onboardingRepository = mockOnboardingRepository;
    when(
      () => mockOnboardingRepository.getStatus(),
    ).thenAnswer((_) async => const OnboardingStatusModel(hasAnswered: false, profile: null));
  });

  Widget buildTestableWidget() {
    return MaterialApp(theme: AppTheme.dark, home: const LoginScreen());
  }

  group('LoginScreen', () {
    testWidgets('renders perfectly with all child components', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.byType(LoginCard), findsOneWidget);
      expect(find.byType(LoginBackground), findsOneWidget);
      expect(find.byType(CustomTextField), findsNWidgets(2));
      // Two GameButtons render here: the primary CTA and Google sign-in.
      expect(find.byType(GameButton), findsNWidgets(2));

      expect(find.text('PETRIMONIUM WALLET'), findsOneWidget);
      expect(find.text('E-mail ou Usuário'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      // 'Entrar' aparece duas vezes em pt: a aba do alternador e o CTA do
      // botão primário. Aqui interessa o CTA.
      expect(find.widgetWithText(GameButton, 'Entrar'), findsOneWidget);
    });

    testWidgets('updates UI text when Translator language changes', (WidgetTester tester) async {
      Translator.currentLanguage = 'en';
      await tester.pumpWidget(buildTestableWidget());

      expect(find.text('Email or Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      // 'Login' now appears twice in English: the Login/Create Account toggle tab
      // and the primary CTA's own label — assert the CTA specifically.
      expect(find.widgetWithText(GameButton, 'Login'), findsOneWidget);

      expect(find.text('E-mail ou Usuário'), findsNothing);
    });

    testWidgets('TextFields accept text input properly and attempt login', (WidgetTester tester) async {
      // A superfície padrão de teste (800x600) é menor que um telefone e o CTA
      // fica fora dela; o fundo cósmico anima sem parar, então rolar até o
      // botão com pumpAndSettle não é opção.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => mockAuthRepository.login(any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestableWidget());

      final emailField = find.descendant(of: find.byType(CustomTextField), matching: find.byType(TextField)).first;

      final passwordField = find.descendant(of: find.byType(CustomTextField), matching: find.byType(TextField)).last;

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);

      final loginBtn = find.widgetWithText(GameButton, 'Entrar');
      await tester.tap(loginBtn);
      await tester.pump(); // Start loading
      await tester.pump(); // Finish loading

      verify(() => mockAuthRepository.login('test@example.com', 'password123')).called(1);
    });
  });
}
