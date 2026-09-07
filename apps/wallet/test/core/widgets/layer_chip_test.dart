import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium/core/theme/app_theme.dart';
import 'package:petrimonium/core/widgets/layer_chip.dart';

void main() {
  Widget buildTestableWidget(DataLayer layer, String label) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: LayerChip(layer: layer, label: label)),
    );
  }

  group('LayerChip', () {
    for (final layer in DataLayer.values) {
      testWidgets('renders its label for $layer', (tester) async {
        await tester.pumpWidget(buildTestableWidget(layer, 'DADO · B3, hoje 09:41'));
        await tester.pump();

        expect(find.text('DADO · B3, hoje 09:41'), findsOneWidget);
      });
    }
  });
}
