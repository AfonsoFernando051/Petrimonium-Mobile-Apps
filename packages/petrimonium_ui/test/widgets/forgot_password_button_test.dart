import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_theme.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

void main() {
  Widget buildTestableWidget(VoidCallback onTap) {
    return MaterialApp(
      theme: TestTheme.dark,
      home: Scaffold(
        body: ForgotPasswordButton(label: 'Esqueceu a senha?', onTap: onTap),
      ),
    );
  }

  group('ForgotPasswordButton', () {
    testWidgets('renders the given label', (tester) async {
      await tester.pumpWidget(buildTestableWidget(() {}));

      expect(find.text('Esqueceu a senha?'), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTestableWidget(() => tapped = true));

      await tester.tap(find.byType(GestureDetector));

      expect(tapped, isTrue);
    });
  });
}
