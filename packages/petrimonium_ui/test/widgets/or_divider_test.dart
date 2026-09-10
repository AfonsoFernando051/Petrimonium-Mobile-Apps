import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_theme.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

void main() {
  testWidgets('OrDivider renders the given label between two dividers', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: TestTheme.dark,
      home: const Scaffold(body: OrDivider(label: 'ou')),
    ));

    expect(find.text('ou'), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));
  });
}
