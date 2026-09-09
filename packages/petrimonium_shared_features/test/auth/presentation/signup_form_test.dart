import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

import '../../test_theme.dart';

void main() {
  Finder fieldAt(int index) =>
      find.descendant(of: find.byType(CustomTextField), matching: find.byType(TextField)).at(index);
  Finder nameField() => fieldAt(0);
  Finder emailField() => fieldAt(1);
  Finder passwordField() => fieldAt(2);
  Finder confirmPasswordField() => fieldAt(3);

  Widget buildTestableWidget({
    Future<void> Function(String, String, String)? onRegister,
    Future<void> Function(String, String)? onLoginAfterRegister,
    Future<void> Function()? onGoogleSignup,
    VoidCallback? onSuccess,
    String Function(Object)? errorMessageBuilder,
  }) {
    return MaterialApp(
      theme: TestTheme.dark,
      home: Scaffold(
        body: SignupForm(
          nameHint: 'Nome',
          emailHint: 'E-mail',
          passwordHint: 'Senha',
          confirmPasswordHint: 'Confirmar senha',
          signupButtonLabel: 'Criar conta',
          googleButtonLabel: 'Continuar com o Google',
          orDividerLabel: 'ou',
          sharedAccountNoticeText: 'Sua conta é a mesma nos apps Petrimonium.',
          onRegister: onRegister ?? (_, __, ___) async {},
          onLoginAfterRegister: onLoginAfterRegister ?? (_, __) async {},
          onGoogleSignup: onGoogleSignup ?? () async {},
          onSuccess: onSuccess ?? () {},
          errorMessageBuilder: errorMessageBuilder ?? (e) => e.toString(),
        ),
      ),
    );
  }

  const validPassword = 'Password1';

  group('SignupForm', () {
    testWidgets('renders four fields, the CTA and the shared-account notice', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.byType(CustomTextField), findsNWidgets(4));
      expect(find.text('Criar conta'), findsOneWidget);
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.byType(SharedAccountNotice), findsOneWidget);
    });

    testWidgets('shows an error snack and does not call onRegister when fields are empty', (tester) async {
      var registerCalled = false;
      await tester.pumpWidget(buildTestableWidget(onRegister: (_, __, ___) async {
        registerCalled = true;
      }));

      await tester.tap(find.text('Criar conta'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Preencha todos os campos obrigatórios.'), findsOneWidget);
      expect(registerCalled, isFalse);
    });

    testWidgets('surfaces a mismatched-confirmation error live under the field', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(passwordField(), validPassword);
      await tester.enterText(confirmPasswordField(), 'somethingElse');
      await tester.pump();

      expect(find.text('As senhas não coincidem.'), findsOneWidget);
    });

    testWidgets('registers, then logs in, then calls onSuccess', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(buildTestableWidget(
        onRegister: (name, email, password) async => calls.add('register:$name:$email:$password'),
        onLoginAfterRegister: (email, password) async => calls.add('login:$email:$password'),
        onSuccess: () => calls.add('success'),
      ));

      await tester.enterText(nameField(), 'Ana');
      await tester.enterText(emailField(), 'ana@example.com');
      await tester.enterText(passwordField(), validPassword);
      await tester.enterText(confirmPasswordField(), validPassword);
      await tester.pump();

      await tester.tap(find.text('Criar conta'));
      await tester.pump();
      await tester.pump();

      expect(calls, [
        'register:Ana:ana@example.com:$validPassword',
        'login:ana@example.com:$validPassword',
        'success',
      ]);
    });

    testWidgets('shows a snack built from errorMessageBuilder when onRegister throws', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        onRegister: (_, __, ___) async => throw Exception('email in use'),
        errorMessageBuilder: (_) => 'e-mail já cadastrado',
      ));

      await tester.enterText(nameField(), 'Ana');
      await tester.enterText(emailField(), 'ana@example.com');
      await tester.enterText(passwordField(), validPassword);
      await tester.enterText(confirmPasswordField(), validPassword);
      await tester.pump();

      await tester.tap(find.text('Criar conta'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Cadastro falhou: e-mail já cadastrado'), findsOneWidget);
    });

    testWidgets('calls onGoogleSignup and onSuccess when the Google button is tapped', (tester) async {
      var googleCalled = false;
      var succeeded = false;
      await tester.pumpWidget(buildTestableWidget(
        onGoogleSignup: () async => googleCalled = true,
        onSuccess: () => succeeded = true,
      ));

      await tester.tap(find.byType(GoogleSignInButton));
      await tester.pump();
      await tester.pump();

      expect(googleCalled, isTrue);
      expect(succeeded, isTrue);
    });
  });
}
