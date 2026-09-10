import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

import '../../test_theme.dart';

void main() {
  Finder emailField() => find.descendant(of: find.byType(CustomTextField), matching: find.byType(TextField)).first;
  Finder passwordField() => find.descendant(of: find.byType(CustomTextField), matching: find.byType(TextField)).last;

  Widget buildTestableWidget({
    Future<void> Function(String, String)? onLogin,
    Future<void> Function()? onGoogleLogin,
    VoidCallback? onSuccess,
    VoidCallback? onForgotPassword,
    String Function(Object)? errorMessageBuilder,
  }) {
    return MaterialApp(
      theme: TestTheme.dark,
      home: Scaffold(
        body: LoginForm(
          emailHint: 'E-mail',
          passwordHint: 'Senha',
          loginButtonLabel: 'Entrar',
          googleButtonLabel: 'Continuar com o Google',
          orDividerLabel: 'ou',
          forgotPasswordLabel: 'Esqueceu a senha?',
          onForgotPassword: onForgotPassword ?? () {},
          sharedAccountNoticeText: 'Sua conta é a mesma nos apps Petrimonium.',
          onLogin: onLogin ?? (_, _) async {},
          onGoogleLogin: onGoogleLogin ?? () async {},
          onSuccess: onSuccess ?? () {},
          errorMessageBuilder: errorMessageBuilder ?? (e) => e.toString(),
        ),
      ),
    );
  }

  group('LoginForm', () {
    testWidgets('renders both fields, the CTAs and the shared-account notice', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.byType(CustomTextField), findsNWidgets(2));
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Esqueceu a senha?'), findsOneWidget);
      expect(find.byType(SharedAccountNotice), findsOneWidget);
    });

    testWidgets('shows an error snack and does not call onLogin when fields are empty', (tester) async {
      var loginCalled = false;
      await tester.pumpWidget(
        buildTestableWidget(
          onLogin: (_, _) async {
            loginCalled = true;
          },
        ),
      );

      await tester.tap(find.text('Entrar'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Preencha e-mail e senha para continuar.'), findsOneWidget);
      expect(loginCalled, isFalse);
    });

    testWidgets('calls onLogin with the entered credentials and onSuccess on completion', (tester) async {
      String? loggedEmail;
      String? loggedPassword;
      var succeeded = false;
      await tester.pumpWidget(
        buildTestableWidget(
          onLogin: (email, password) async {
            loggedEmail = email;
            loggedPassword = password;
          },
          onSuccess: () => succeeded = true,
        ),
      );

      await tester.enterText(emailField(), 'user@example.com');
      await tester.enterText(passwordField(), 'password123');
      await tester.pump();

      await tester.tap(find.text('Entrar'));
      await tester.pump();
      await tester.pump();

      expect(loggedEmail, 'user@example.com');
      expect(loggedPassword, 'password123');
      expect(succeeded, isTrue);
    });

    testWidgets('shows a snack built from errorMessageBuilder when onLogin throws', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          onLogin: (_, _) async => throw Exception('bad credentials'),
          errorMessageBuilder: (_) => 'credenciais inválidas',
        ),
      );

      await tester.enterText(emailField(), 'user@example.com');
      await tester.enterText(passwordField(), 'wrongpass');
      await tester.pump();

      await tester.tap(find.text('Entrar'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Login falhou: credenciais inválidas'), findsOneWidget);
    });

    testWidgets('tapping the forgot-password link invokes onForgotPassword', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTestableWidget(onForgotPassword: () => tapped = true));

      await tester.tap(find.text('Esqueceu a senha?'));

      expect(tapped, isTrue);
    });

    testWidgets('calls onGoogleLogin and onSuccess when the Google button is tapped', (tester) async {
      var googleCalled = false;
      var succeeded = false;
      await tester.pumpWidget(
        buildTestableWidget(onGoogleLogin: () async => googleCalled = true, onSuccess: () => succeeded = true),
      );

      await tester.tap(find.byType(GoogleSignInButton));
      await tester.pump();
      await tester.pump();

      expect(googleCalled, isTrue);
      expect(succeeded, isTrue);
    });
  });
}
