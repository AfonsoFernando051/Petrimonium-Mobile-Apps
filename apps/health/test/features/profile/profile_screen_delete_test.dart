import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_health/core/app/health_scope.dart';
import 'package:petrimonium_health/core/i18n/locale_controller.dart';
import 'package:petrimonium_health/features/health/data/health_repository.dart';
import 'package:petrimonium_health/features/health/presentation/health_controller.dart';
import 'package:petrimonium_health/features/profile/presentation/profile_screen.dart';
import 'package:petrimonium_health/l10n/app_localizations.dart';

/// Cobertura do caminho destrutivo do Health: apagar a conta é irreversível,
/// por isso interessa provar o diálogo obrigatório, a limpeza da sessão local
/// e — sobretudo — que uma falha não deixa o utilizador a achar que apagou.
void main() {
  Future<_DeleteRepository> pumpProfile(
    WidgetTester tester, {
    bool failDelete = false,
    bool rejectCredential = false,
  }) async {
    final repository = _DeleteRepository(failDelete: failDelete, rejectCredential: rejectCredential);
    final controller = HealthController(repository: repository, localeController: LocaleController());

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: HealthScope(controller: controller, child: const ProfileScreen()),
      ),
    );
    await tester.pump();
    return repository;
  }

  Future<void> openDeleteDialog(WidgetTester tester) async {
    final button = find.text('Excluir minha conta');
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  /// Confirma a intenção e, a seguir, preenche a senha no diálogo de reautenticação —
  /// o backend recusa a exclusão sem credencial, por isso é assim que o caminho feliz corre.
  Future<void> confirmAndReauthenticate(WidgetTester tester, {String password = 'senha-certa'}) async {
    // O rótulo aparece duas vezes: a linha do perfil e a ação do diálogo.
    await tester.tap(find.text('Excluir minha conta').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), password);
    await tester.tap(find.text('Excluir minha conta').last);
    await tester.pumpAndSettle();
  }

  testWidgets('cancelling the dialog deletes nothing', (tester) async {
    final repository = await pumpProfile(tester);

    await openDeleteDialog(tester);
    expect(find.text('Excluir a conta?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 0);
    expect(repository.logoutCalls, 0);
  });

  testWidgets('confirming deletes the account and clears the local session', (tester) async {
    final repository = await pumpProfile(tester);

    await openDeleteDialog(tester);
    await confirmAndReauthenticate(tester);

    expect(repository.deleteCalls, 1);
    expect(repository.lastPassword, 'senha-certa');
    // Os tokens têm de sair do dispositivo, senão ficam a apontar para uma
    // conta que já não existe.
    expect(repository.logoutCalls, 1);
  });

  testWidgets('a failed deletion is reported and keeps the session', (tester) async {
    final repository = await pumpProfile(tester, failDelete: true);

    await openDeleteDialog(tester);
    await confirmAndReauthenticate(tester);

    expect(repository.deleteCalls, 1);
    expect(repository.logoutCalls, 0);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  /// Confirmar a intenção não pode, sozinho, apagar nada: é exatamente o que uma sessão
  /// roubada consegue fazer. Sair do diálogo de credencial tem de deixar a conta intacta.
  testWidgets('confirming without supplying a credential deletes nothing', (tester) async {
    final repository = await pumpProfile(tester);

    await openDeleteDialog(tester);
    await tester.tap(find.text('Excluir minha conta').last);
    await tester.pumpAndSettle();

    // O diálogo de reautenticação está aberto; sair dele sem senha não apaga.
    expect(find.text('Confirme que é você'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 0);
    expect(repository.logoutCalls, 0);
  });

  testWidgets('a rejected credential says so and keeps the account', (tester) async {
    final repository = await pumpProfile(tester, rejectCredential: true);

    await openDeleteDialog(tester);
    await confirmAndReauthenticate(tester, password: 'senha-errada');

    expect(repository.logoutCalls, 0);
    expect(find.text('Senha incorreta. A conta não foi excluída.'), findsOneWidget);
  });
}

class _DeleteRepository implements HealthRepository {
  _DeleteRepository({required this.failDelete, this.rejectCredential = false});

  final bool failDelete;
  final bool rejectCredential;
  int deleteCalls = 0;
  int logoutCalls = 0;
  String? lastPassword;

  @override
  Future<void> deleteAccount({String? password, String? googleIdToken}) async {
    lastPassword = password;
    if (rejectCredential) throw const InvalidCredentialsException();
    deleteCalls++;
    if (failDelete) throw Exception('500');
  }

  @override
  Future<String?> obtainGoogleIdToken() async => null;

  @override
  Future<void> logout() async => logoutCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
