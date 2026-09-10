import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_health/core/app/health_scope.dart';
import 'package:petrimonium_health/core/i18n/locale_controller.dart';
import 'package:petrimonium_health/core/theme/health_theme.dart';
import 'package:petrimonium_health/features/auth/presentation/login_screen.dart';
import 'package:petrimonium_health/features/health/data/health_repository.dart';
import 'package:petrimonium_health/features/health/presentation/health_controller.dart';
import 'package:petrimonium_health/l10n/app_localizations.dart';

/// Estrutura do artboard `LoginHealth` do canvas de design.
void main() {
  Future<HealthController> pumpLogin(WidgetTester tester) async {
    final controller = HealthController(repository: _StubRepository(), localeController: LocaleController());
    await tester.pumpWidget(
      AnimatedBuilder(
        animation: controller,
        builder: (context, _) => MaterialApp(
          theme: buildHealthTheme(),
          locale: const Locale('pt', 'BR'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: HealthScope(controller: controller, child: const LoginScreen()),
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  testWidgets('the auth toggle reads Entrar / Criar Conta, not Login / Cadastro', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Criar Conta'), findsOneWidget);
    expect(find.text('Cadastro'), findsNothing);
    expect(find.text('Login'), findsNothing);
    // "Entrar" aparece duas vezes: a face do controlo e o botão principal.
    expect(find.text('Entrar'), findsNWidgets(2));
  });

  testWidgets('the shared-account note closes the screen, below the Google button', (tester) async {
    await pumpLogin(tester);

    final note = find.textContaining('Mesma conta Petrimonium');
    final google = find.textContaining('Continuar com Google');
    expect(note, findsOneWidget);
    expect(google, findsOneWidget);

    // No artboard a nota é rodapé; antes ficava a meio, separando os campos
    // do botão de entrar.
    expect(tester.getTopLeft(note).dy, greaterThan(tester.getTopLeft(google).dy));
  });

  testWidgets('the note names all three apps', (tester) async {
    await pumpLogin(tester);

    final note = tester.widget<Text>(find.textContaining('Mesma conta Petrimonium'));
    final text = note.data!;
    for (final app in ['Wallet', 'Academy', 'Health']) {
      expect(text, contains(app), reason: app);
    }
  });

  testWidgets('the toggle is a segmented control: active face is a white pill', (tester) async {
    final controller = await pumpLogin(tester);

    Color? faceColour(String label) {
      final box = tester.widget<AnimatedContainer>(
        find.ancestor(of: find.text(label), matching: find.byType(AnimatedContainer)).first,
      );
      return (box.decoration as BoxDecoration?)?.color;
    }

    // Selecção a branco, não a terracota cheio (que é o HealthChip usado
    // noutros ecrãs e que aqui destoava do artboard).
    expect(faceColour('Criar Conta'), Colors.transparent);
    expect(controller.navigation.authMode, AuthMode.login);

    await tester.tap(find.text('Criar Conta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(controller.navigation.authMode, AuthMode.signup);
    expect(faceColour('Criar Conta'), HealthColors.card);
  });

  testWidgets('signup swaps the copy and drops the forgot-password link', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Esqueceu a senha?'), findsOneWidget);

    await tester.tap(find.text('Criar Conta'));
    await tester.pump();

    expect(find.text('Esqueceu a senha?'), findsNothing);
    expect(find.textContaining('única para Wallet, Academy e Health'), findsOneWidget);
  });
}

class _StubRepository implements HealthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
