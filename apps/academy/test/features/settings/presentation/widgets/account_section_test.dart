import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/settings/presentation/widgets/account_section.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  Widget buildTestableWidget({String? email, VoidCallback? onLogout, VoidCallback? onDeleteAccount}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: AccountSection(
          sectionLabel: (label) => Text(label),
          email: email,
          onLogout: onLogout ?? () {},
          onDeleteAccount: onDeleteAccount ?? () {},
        ),
      ),
    );
  }

  group('AccountSection', () {
    testWidgets('renders the section label, the email and a logout button', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(email: 'user@example.com'));

      expect(find.text('CONTA'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('omits the email row and divider when email is null', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(email: null));

      expect(find.byIcon(Icons.person_outline), findsNothing);
      expect(find.byType(Divider), findsNothing);
      expect(find.text('Sair'), findsOneWidget);
    });

    testWidgets('invokes onLogout when the logout button is tapped', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTestableWidget(email: 'user@example.com', onLogout: () => tapped = true));

      await tester.tap(find.text('Sair'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders the delete-account button below logout', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(email: 'user@example.com'));

      expect(find.text('Excluir minha conta'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Subordinate to Sair, never above it — it must not be the button the
      // thumb lands on by accident.
      final logoutY = tester.getCenter(find.text('Sair')).dy;
      final deleteY = tester.getCenter(find.text('Excluir minha conta')).dy;
      expect(deleteY, greaterThan(logoutY));
    });

    testWidgets('invokes onDeleteAccount when the delete button is tapped', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTestableWidget(email: 'user@example.com', onDeleteAccount: () => tapped = true));

      await tester.tap(find.text('Excluir minha conta'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('tapping delete does not trigger logout', (WidgetTester tester) async {
      var loggedOut = false;
      await tester.pumpWidget(buildTestableWidget(email: 'user@example.com', onLogout: () => loggedOut = true));

      await tester.tap(find.text('Excluir minha conta'));
      await tester.pump();

      expect(loggedOut, isFalse);
    });

  });
}
