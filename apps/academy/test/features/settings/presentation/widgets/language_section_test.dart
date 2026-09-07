import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/settings/presentation/widgets/language_section.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  Widget buildTestableWidget({ValueChanged<String>? onLanguageSelected}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: LanguageSection(
          sectionLabel: (label) => Text(label),
          onLanguageSelected: onLanguageSelected ?? (_) {},
        ),
      ),
    );
  }

  group('LanguageSection', () {
    testWidgets('renders section label and all three language rows', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.text('IDIOMA'), findsOneWidget);
      expect(find.text('Português (Brasil)'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
    });

    testWidgets('marks exactly one language as selected', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // O artboard desenha o círculo em todas as linhas — vazio nas não
      // escolhidas — e só a escolhida leva o visto dentro.
      expect(find.byType(OptionRow), findsNWidgets(4));
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        tester.widgetList<OptionRow>(find.byType(OptionRow)).where((r) => r.selected).length,
        1,
      );
    });

    testWidgets('shows the check next to English when currentLanguage is en', (tester) async {
      Translator.currentLanguage = 'en';
      await tester.pumpWidget(buildTestableWidget());

      final englishRow = find.ancestor(
        of: find.text('English'),
        matching: find.byType(InkWell),
      );
      expect(
        find.descendant(of: englishRow, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
    });

    testWidgets('invokes onLanguageSelected with the tapped language code', (tester) async {
      String? selected;
      await tester.pumpWidget(buildTestableWidget(onLanguageSelected: (code) => selected = code));

      await tester.tap(find.text('English'));
      await tester.pump();

      expect(selected, 'en');
    });

    testWidgets('invokes onLanguageSelected with es when the Spanish row is tapped', (tester) async {
      String? selected;
      await tester.pumpWidget(buildTestableWidget(onLanguageSelected: (code) => selected = code));

      await tester.tap(find.text('Español'));
      await tester.pump();

      expect(selected, 'es');
    });
  });
}
