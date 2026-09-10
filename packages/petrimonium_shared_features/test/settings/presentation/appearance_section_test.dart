import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThemeController.themeModeNotifier.value = ThemeMode.system;
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: TestTheme.dark,
      home: Scaffold(
        body: AppearanceSection(
          sectionLabel: (label) => Text(label),
          sectionTitle: 'Aparência',
          lightLabel: 'Claro',
          lightDescription: 'Brilhante, limpo e acolhedor',
          darkLabel: 'Escuro',
          darkDescription: 'Premium, imersivo e futurista',
          systemLabel: 'Sistema',
          systemDescription: 'Segue as configurações do aparelho',
        ),
      ),
    );
  }

  group('AppearanceSection', () {
    testWidgets('renders the section label and all three theme option cards', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.text('APARÊNCIA'), findsOneWidget);
      expect(find.byType(AppearanceOptionCard), findsNWidgets(3));
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Escuro'), findsOneWidget);
      expect(find.text('Sistema'), findsOneWidget);
    });

    testWidgets('highlights the card matching the current ThemeController mode', (WidgetTester tester) async {
      ThemeController.themeModeNotifier.value = ThemeMode.dark;
      await tester.pumpWidget(buildTestableWidget());

      final cards = tester.widgetList<AppearanceOptionCard>(find.byType(AppearanceOptionCard)).toList();
      final selected = cards.where((c) => c.selected).toList();
      expect(selected, hasLength(1));
      expect(selected.first.label, 'Escuro');
    });

    testWidgets('tapping a card calls ThemeController.setThemeMode and updates the highlight', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.text('Escuro'));
      await tester.pump();

      expect(ThemeController.currentThemeMode, ThemeMode.dark);
      final cards = tester.widgetList<AppearanceOptionCard>(find.byType(AppearanceOptionCard)).toList();
      expect(cards.firstWhere((c) => c.label == 'Escuro').selected, isTrue);
      expect(cards.firstWhere((c) => c.label == 'Sistema').selected, isFalse);
    });
  });
}
