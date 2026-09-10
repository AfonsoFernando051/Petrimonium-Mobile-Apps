import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import '../../test_theme.dart';

/// The two calls these screens make. Mocking a narrow interface rather than
/// each product's `AuthRepository` keeps the `verify(...)` assertions below
/// exactly as they were while dropping the dependency on an app.
abstract class _AuthApi {
  Future<void> requestPasswordReset(String email);
  Future<void> resetPassword(String token, String newPassword);
}

class MockAuthRepository extends Mock implements _AuthApi {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  ResetPasswordScreen resetScreen() => ResetPasswordScreen(
    background: const SizedBox.shrink(),
    onResetPassword: mockAuthRepository.resetPassword,
    errorMessageBuilder: (e) => e.toString(),
    copy: (
      title: 'Redefinir senha',
      subtitle: 'Cole o código que enviamos por e-mail e escolha uma nova senha.',
      tokenHint: 'Código de redefinição',
      newPasswordHint: 'Nova senha',
      confirmPasswordHint: 'Confirmar Senha',
      submitLabel: 'Redefinir senha',
      successMessage: 'Senha redefinida com sucesso! Faça login com sua nova senha.',
      mismatchError: 'As senhas não coincidem.',
      fieldsRequiredError: 'Preencha todos os campos.',
    ),
  );

  // The backdrop is each product's own `LoginBackground`; an empty box keeps
  // the widget tree the assertions care about unchanged — and, unlike the
  // real one, ends the frame, so these no longer need the never-settle dance.
  ForgotPasswordScreen screen(BuildContext context) => ForgotPasswordScreen(
    background: const SizedBox.shrink(),
    onRequestReset: mockAuthRepository.requestPasswordReset,
    errorMessageBuilder: (e) => e.toString().replaceFirst('Exception: ', ''),
    onGoToReset: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => resetScreen())),
    copy: (
      title: 'Recuperar senha',
      subtitle: 'Digite seu e-mail e enviaremos um link para redefinir sua senha.',
      emailHint: 'Seu e-mail',
      sendLabel: 'Enviar link',
      confirmationMessage: 'Se existir uma conta com esse e-mail, você receberá instruções em instantes.',
      haveCodeLabel: 'Já tenho um código de redefinição',
    ),
  );

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: TestTheme.dark,
      home: Builder(builder: screen),
    );
  }

  group('ForgotPasswordScreen', () {
    testWidgets('renders title, subtitle, email field, and send button', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.text('Recuperar senha'), findsOneWidget);
      expect(find.text('Digite seu e-mail e enviaremos um link para redefinir sua senha.'), findsOneWidget);
      expect(find.byType(CustomTextField), findsOneWidget);
      expect(find.text('Enviar link'), findsOneWidget);
      expect(find.text('Já tenho um código de redefinição'), findsOneWidget);
    });

    testWidgets('does not submit when email is empty', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.text('Enviar link'));
      await tester.pump();

      verifyNever(() => mockAuthRepository.requestPasswordReset(any()));
      expect(find.text('Enviar link'), findsOneWidget);
    });

    testWidgets('submits email and shows confirmation message on success', (tester) async {
      when(() => mockAuthRepository.requestPasswordReset(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(find.byType(TextField), 'user@example.com');
      await tester.tap(find.text('Enviar link'));
      await tester.pump(); // loading
      await tester.pump(); // settle

      verify(() => mockAuthRepository.requestPasswordReset('user@example.com')).called(1);
      expect(find.text('Se existir uma conta com esse e-mail, você receberá instruções em instantes.'), findsOneWidget);
      expect(find.byType(CustomTextField), findsNothing);
    });

    testWidgets('shows friendly error snackbar when request fails', (tester) async {
      when(() => mockAuthRepository.requestPasswordReset(any())).thenThrow(Exception('server down'));

      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(find.byType(TextField), 'user@example.com');
      await tester.tap(find.text('Enviar link'));
      await tester.pump();
      await tester.pump();

      expect(find.text('server down'), findsOneWidget);
    });

    testWidgets('navigates to ResetPasswordScreen via the code link', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.text('Já tenho um código de redefinição'));
      // Not pumpAndSettle(): both screens render a CosmicBackground whose
      // drift/twinkle AnimationControllers repeat indefinitely.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ResetPasswordScreen), findsOneWidget);
    });

    testWidgets('back button pops the screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TestTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen(context))),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Not pumpAndSettle() anywhere here: ForgotPasswordScreen's
      // CosmicBackground repeats its drift/twinkle animations forever.
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      // A touch over the 300ms default MaterialPageRoute transition, plus a
      // trailing zero-duration pump, so the pop animation fully completes
      // and the route is actually removed (landing exactly on the boundary
      // can leave it one frame short of that).
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.byType(ForgotPasswordScreen), findsNothing);
    });
  });
}
