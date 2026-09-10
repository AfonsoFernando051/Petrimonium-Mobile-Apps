import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_theme.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: TestTheme.dark,
    home: Scaffold(body: child),
  );

  testWidgets('renders the given label', (tester) async {
    await tester.pumpWidget(wrap(GoogleSignInButton(label: 'Continuar com o Google', onPressed: () {})));

    expect(find.text('Continuar com o Google'), findsOneWidget);
  });

  testWidgets('tapping invokes onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(GoogleSignInButton(label: 'Google', onPressed: () => tapped = true)));

    await tester.tap(find.byType(GoogleSignInButton));
    await tester.pump(const Duration(milliseconds: 150));

    expect(tapped, isTrue);
  });

  testWidgets('isLoading shows a spinner instead of the label', (tester) async {
    await tester.pumpWidget(wrap(const GoogleSignInButton(label: 'Google', isLoading: true)));

    expect(find.text('Google'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
