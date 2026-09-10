import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/auth/data/repositories/auth_repository.dart';
import 'package:petrimonium_wallet/features/auth/presentation/password_recovery_routes.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// Both screens live in `petrimonium_shared_features` and are handed their
/// copy, so "the screen rendered" no longer proves this app passed it the
/// right strings — every key here could be mis-wired and the screen would
/// still appear. These assert the wiring itself.
void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
    DI.authRepository = MockAuthRepository();
  });

  // Never pumpAndSettle: LoginBackground animates indefinitely.
  testWidgets('the forgot-password route is wired with this product\'s copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(builder: buildForgotPasswordScreen),
      ),
    );
    await tester.pump();

    expect(find.text('Recuperar senha'), findsOneWidget);
    expect(find.text('Digite seu e-mail e enviaremos um link para redefinir sua senha.'), findsOneWidget);
    expect(find.text('Enviar link'), findsOneWidget);
    expect(find.text('Já tenho um código de redefinição'), findsOneWidget);
  });

  testWidgets('the reset-password route is wired with this product\'s copy', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: buildResetPasswordScreen()));
    await tester.pump();

    expect(find.text('Redefinir senha'), findsNWidgets(2)); // title + CTA
    expect(find.text('Cole o código que enviamos por e-mail e escolha uma nova senha.'), findsOneWidget);
    expect(find.text('Código de redefinição'), findsOneWidget);
    expect(find.text('Nova senha'), findsOneWidget);
    expect(find.text('Confirmar Senha'), findsOneWidget);
  });
}
