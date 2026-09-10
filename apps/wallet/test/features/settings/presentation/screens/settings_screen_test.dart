import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/auth/data/repositories/auth_repository.dart';
import 'package:petrimonium_wallet/features/auth/presentation/screens/login_screen.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/settings/data/repositories/settings_repository.dart';
import 'package:petrimonium_wallet/features/settings/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockMascotRepository extends Mock implements MascotRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockMascotRepository mockMascotRepository;
  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});
    ThemeController.themeModeNotifier.value = ThemeMode.system;

    mockAuthRepository = MockAuthRepository();
    mockMascotRepository = MockMascotRepository();
    mockSettingsRepository = MockSettingsRepository();

    when(() => mockAuthRepository.getSavedEmail()).thenAnswer((_) async => 'user@example.com');
    when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
    when(() => mockMascotRepository.loadProfile()).thenAnswer((_) async => PetProfile(name: 'Rex'));
    when(() => mockMascotRepository.saveName(any())).thenAnswer((_) async {});
    when(() => mockSettingsRepository.syncLanguage(any())).thenAnswer((_) async {});
    when(() => mockSettingsRepository.deleteAccount()).thenAnswer((_) async {});

    DI.authRepository = mockAuthRepository;
    DI.mascotRepository = mockMascotRepository;
    DI.settingsRepository = mockSettingsRepository;
  });

  Widget buildTestableWidget() {
    return MaterialApp(theme: AppTheme.dark, home: const SettingsScreen());
  }

  // The Settings body is taller than the default 800x600 test viewport, so
  // every tap below scrolls its target into view first.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
  }

  group('SettingsScreen', () {
    testWidgets('renders every section once local preferences finish loading', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      // CosmicBackground has an indefinitely-repeating animation — never pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Configurações'), findsOneWidget);
      expect(find.byType(CompanionSection), findsOneWidget);
      expect(find.byType(LanguageSection), findsOneWidget);
      expect(find.byType(AppearanceSection), findsOneWidget);
      expect(find.byType(NotificationsSection), findsOneWidget);
      expect(find.byType(PrivacySection), findsOneWidget);
      expect(find.byType(AccountSection), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.text('Rex'), findsOneWidget);
    });

    // The sections live in `petrimonium_shared_features` and are handed their
    // copy, so a section rendering at all no longer proves this screen passed
    // it the right strings — findsOneWidget above would still pass with every
    // key mis-wired. These assert the wiring itself.
    testWidgets('hands each section the copy it is supposed to show', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      for (final title in ['COMPANHEIRO', 'IDIOMA', 'PAÍS', 'APARÊNCIA', 'NOTIFICAÇÕES', 'PRIVACIDADE', 'CONTA']) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(find.text('Nome do companheiro'), findsOneWidget);
      expect(find.text('Português (Brasil)'), findsOneWidget);
      expect(find.text('Brasil'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Lembretes de missões diárias'), findsOneWidget);
      expect(find.text('Aparecer nos rankings'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);
    });

    testWidgets('toggling a notification switch persists the new value to SharedPreferences', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapVisible(tester, find.text('Lembretes de missões diárias'));
      await tester.pump(const Duration(milliseconds: 300));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings_daily_mission_reminders'), isFalse);
    });

    testWidgets('renaming the pet updates the shown name and persists via the mascot repository', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapVisible(tester, find.text('Renomear'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Bolt');
      await tester.tap(find.text('Renomear').last); // the dialog's confirm action — always on-screen (centered dialog)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockMascotRepository.saveName('Bolt')).called(1);
      expect(find.text('Bolt'), findsOneWidget);
      expect(find.text('Nome atualizado!'), findsOneWidget);
    });

    testWidgets('cancelling the logout dialog does not call logout', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapVisible(tester, find.text('Sair'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Sair do Invest Game?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => mockAuthRepository.logout());
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('confirming the logout dialog logs out and navigates to LoginScreen', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapVisible(tester, find.text('Sair'));
      await tester.pump(const Duration(milliseconds: 300));

      // Two "Sair" widgets now exist: the section's button and the dialog's
      // confirm action — the dialog's is the more recently added, i.e. last.
      await tester.tap(find.text('Sair').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Let the push-and-remove page transition finish so the old
      // SettingsScreen route is actually disposed, not just covered.
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockAuthRepository.logout()).called(1);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);
    });
    testWidgets('cancelling the delete-account dialog deletes nothing', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapVisible(tester, find.text('Excluir minha conta'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Excluir a conta?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => mockSettingsRepository.deleteAccount());
      verifyNever(() => mockAuthRepository.logout());
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets(
      'confirming the delete-account dialog erases the account, clears the session and navigates to LoginScreen',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tapVisible(tester, find.text('Excluir minha conta'));
        await tester.pump(const Duration(milliseconds: 300));

        // Two "Excluir minha conta" widgets now exist: the section's button and
        // the dialog's confirm action — the dialog's is the last one added.
        await tester.tap(find.text('Excluir minha conta').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 500));

        verify(() => mockSettingsRepository.deleteAccount()).called(1);
        // The local session has to be cleared too, otherwise the device keeps
        // tokens for an account that no longer exists.
        verify(() => mockAuthRepository.logout()).called(1);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(SettingsScreen), findsNothing);
      },
    );

    testWidgets('a failed deletion reports the error and leaves the user signed in', (WidgetTester tester) async {
      when(() => mockSettingsRepository.deleteAccount()).thenThrow(Exception('Não foi possível excluir a conta'));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapVisible(tester, find.text('Excluir minha conta'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Excluir minha conta').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Não foi possível excluir a conta'), findsOneWidget);
      // The account still exists, so the session must survive: no logout, no
      // navigation away from Settings.
      verifyNever(() => mockAuthRepository.logout());
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('a successful deletion still signs out locally when the remote logout fails', (
      WidgetTester tester,
    ) async {
      // Expected: /auth/logout answers 401 because the account is already gone.
      when(() => mockAuthRepository.logout()).thenThrow(Exception('401'));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapVisible(tester, find.text('Excluir minha conta'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Excluir minha conta').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockSettingsRepository.deleteAccount()).called(1);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);
    });
  });
}
