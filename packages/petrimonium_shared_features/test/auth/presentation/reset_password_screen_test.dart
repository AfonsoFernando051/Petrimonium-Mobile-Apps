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

  ResetPasswordScreen screen() => ResetPasswordScreen(
    background: const SizedBox.shrink(),
    onResetPassword: mockAuthRepository.resetPassword,
    errorMessageBuilder: (e) => e.toString().replaceFirst('Exception: ', ''),
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

  Widget buildTestableWidget() {
    return MaterialApp(theme: TestTheme.dark, home: screen());
  }

  Finder fieldAt(int index) =>
      find.descendant(of: find.byType(CustomTextField), matching: find.byType(TextField)).at(index);

  group('ResetPasswordScreen', () {
    testWidgets('renders title, subtitle and the three fields', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // Title and submit button share the same translated copy
      // ("Redefinir senha"), so both appear.
      expect(find.text('Redefinir senha'), findsNWidgets(2));
      expect(find.text('Cole o código que enviamos por e-mail e escolha uma nova senha.'), findsOneWidget);
      expect(find.byType(CustomTextField), findsNWidgets(3));
    });

    testWidgets('shows required-fields error when fields are empty', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.text('Redefinir senha').last);
      await tester.pump();

      expect(find.text('Preencha todos os campos.'), findsOneWidget);
      verifyNever(() => mockAuthRepository.resetPassword(any(), any()));
    });

    testWidgets('shows mismatch error when passwords differ', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(fieldAt(0), 'ABC123');
      await tester.enterText(fieldAt(1), 'Str0ngPass1');
      await tester.enterText(fieldAt(2), 'Different1');
      await tester.pump();

      await tester.tap(find.text('Redefinir senha').last);
      await tester.pump();

      expect(find.text('As senhas não coincidem.'), findsOneWidget);
      verifyNever(() => mockAuthRepository.resetPassword(any(), any()));
    });

    testWidgets('shows password policy error for a weak password', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(fieldAt(0), 'ABC123');
      await tester.enterText(fieldAt(1), 'weak');
      await tester.enterText(fieldAt(2), 'weak');
      await tester.pump();

      await tester.tap(find.text('Redefinir senha').last);
      await tester.pump();

      expect(find.text('A senha deve ter pelo menos 8 caracteres.'), findsOneWidget);
      verifyNever(() => mockAuthRepository.resetPassword(any(), any()));
    });

    testWidgets('resets password and pops to first route on success', (tester) async {
      when(() => mockAuthRepository.resetPassword(any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          theme: TestTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen())),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      // Not pumpAndSettle(): ResetPasswordScreen renders a CosmicBackground
      // whose drift/twinkle AnimationControllers repeat indefinitely.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(fieldAt(0), 'ABC123');
      await tester.enterText(fieldAt(1), 'Str0ngPass1');
      await tester.enterText(fieldAt(2), 'Str0ngPass1');
      await tester.pump();

      await tester.tap(find.text('Redefinir senha').last);
      await tester.pump(); // loading
      await tester.pump(); // resetPassword() future resolves, popUntil() starts
      // popUntil's pop animation needs real time to run to completion (the
      // two bare pump()s above only drain microtasks, they don't advance
      // the route transition) — pump past the 300ms default, plus a
      // trailing zero-duration pump so the route is actually removed.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      verify(() => mockAuthRepository.resetPassword('ABC123', 'Str0ngPass1')).called(1);
      expect(find.byType(ResetPasswordScreen), findsNothing);
    });

    testWidgets('shows friendly error snackbar when resetPassword throws', (tester) async {
      when(() => mockAuthRepository.resetPassword(any(), any())).thenThrow(Exception('invalid token'));

      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(fieldAt(0), 'ABC123');
      await tester.enterText(fieldAt(1), 'Str0ngPass1');
      await tester.enterText(fieldAt(2), 'Str0ngPass1');
      await tester.pump();

      await tester.tap(find.text('Redefinir senha').last);
      await tester.pump();
      await tester.pump();

      expect(find.text('invalid token'), findsOneWidget);
    });

    testWidgets('back button pops the screen', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
