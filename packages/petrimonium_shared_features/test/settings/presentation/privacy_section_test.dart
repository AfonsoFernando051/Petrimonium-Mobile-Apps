import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

import '../../test_theme.dart';

void main() {
  Widget buildTestableWidget({bool showOnRankings = true, ValueChanged<bool>? onChanged}) {
    return MaterialApp(
      theme: TestTheme.dark,
      home: Scaffold(
        body: PrivacySection(
          sectionLabel: (label) => Text(label),
          sectionTitle: 'Privacidade',
          showOnRankingsLabel: 'Aparecer nos rankings',
          showOnRankings: showOnRankings,
          onShowOnRankingsChanged: onChanged ?? (_) {},
        ),
      ),
    );
  }

  group('PrivacySection', () {
    testWidgets('renders the section label and the ranking-visibility switch reflecting its value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(showOnRankings: true));

      expect(find.text('PRIVACIDADE'), findsOneWidget);
      expect(find.text('Aparecer nos rankings'), findsOneWidget);
      expect(tester.widget<SettingsSwitchTile>(find.byType(SettingsSwitchTile)).value, isTrue);
    });

    testWidgets('reflects a false value', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(showOnRankings: false));

      expect(tester.widget<SettingsSwitchTile>(find.byType(SettingsSwitchTile)).value, isFalse);
    });

    testWidgets('toggling the switch calls onShowOnRankingsChanged with the new value', (WidgetTester tester) async {
      bool? newValue;
      await tester.pumpWidget(buildTestableWidget(showOnRankings: true, onChanged: (v) => newValue = v));

      await tester.tap(find.text('Aparecer nos rankings'));
      await tester.pump();

      expect(newValue, isFalse);
    });
  });
}
