import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import '../../test_theme.dart';

void main() {
  Widget buildTestableWidget({String? petName, VoidCallback? onRename, Color accentColor = const Color(0xFFFF2A85)}) {
    return MaterialApp(
      theme: TestTheme.dark,
      home: Scaffold(
        body: CompanionSection(
          sectionLabel: (label) => Text(label),
          sectionTitle: 'Companheiro',
          renamePetLabel: 'Nome do companheiro',
          renamePetButtonLabel: 'Renomear',
          accentColor: accentColor,
          petName: petName,
          onRename: onRename ?? () {},
        ),
      ),
    );
  }

  group('CompanionSection', () {
    testWidgets('renders section label and pet name', (tester) async {
      await tester.pumpWidget(buildTestableWidget(petName: 'Rex'));

      expect(find.text('COMPANHEIRO'), findsOneWidget);
      expect(find.text('Nome do companheiro'), findsOneWidget);
      expect(find.text('Rex'), findsOneWidget);
      expect(find.text('Renomear'), findsOneWidget);
    });

    testWidgets('renders a dash placeholder when petName is null', (tester) async {
      await tester.pumpWidget(buildTestableWidget(petName: null));

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('renders a dash placeholder when petName is empty', (tester) async {
      await tester.pumpWidget(buildTestableWidget(petName: ''));

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('invokes onRename when the rename button is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTestableWidget(petName: 'Rex', onRename: () => tapped = true));

      await tester.tap(find.text('Renomear'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('paints the icon and the rename button in the accent it is given', (tester) async {
      // This section used to read `AppColors.neonPink`, which is hot pink in
      // Academy and emerald in Wallet. Hard-coding either would silently
      // re-skin the other product, so the colour has to come from the caller.
      const accent = Color(0xFF3FE0B0);
      await tester.pumpWidget(buildTestableWidget(petName: 'Rex', accentColor: accent));

      expect(tester.widget<Icon>(find.byIcon(Icons.pets)).color, accent);
      final label = tester.widget<Text>(find.text('Renomear'));
      expect(label.style?.color, accent);
    });
  });
}
