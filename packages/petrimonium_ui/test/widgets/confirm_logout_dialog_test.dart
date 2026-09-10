import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_theme.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

void main() {
  setUp(() {});

  Widget buildTestableWidget(void Function(bool?) onResult) {
    return MaterialApp(
      theme: TestTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await ConfirmLogoutDialog.show(
                context,
                title: 'Sair da conta?',
                message: 'Você precisará entrar novamente.',
                cancelLabel: 'Cancelar',
                confirmLabel: 'Sair',
              );
              onResult(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  group('ConfirmLogoutDialog', () {
    testWidgets('shows the title and message', (tester) async {
      await tester.pumpWidget(buildTestableWidget((_) {}));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Sair'), findsWidgets);
    });

    testWidgets('tapping cancel resolves to false and dismisses the dialog', (tester) async {
      bool? result;
      await tester.pumpWidget(buildTestableWidget((r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('tapping logout resolves to true and dismisses the dialog', (tester) async {
      bool? result;
      await tester.pumpWidget(buildTestableWidget((r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sair').last);
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
