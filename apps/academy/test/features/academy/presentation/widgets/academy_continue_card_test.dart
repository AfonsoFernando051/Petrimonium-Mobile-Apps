import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/features/academy/presentation/widgets/academy_continue_card.dart';

import '../../academy_test_fixtures.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  Widget buildTestable(VoidCallback onStart) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: AcademyContinueCard(lesson: testLesson1, onStart: onStart),
      ),
    );
  }

  group('AcademyContinueCard', () {
    testWidgets('renders lesson title and xp reward', (tester) async {
      await tester.pumpWidget(buildTestable(() {}));
      // A single pump is enough to lay out the flat GameButton.
      await tester.pump();

      expect(find.text(testLesson1.title), findsOneWidget);
      expect(find.byType(GameButton), findsOneWidget);
    });

    testWidgets('invokes onStart when the CTA is tapped', (tester) async {
      var started = false;
      await tester.pumpWidget(buildTestable(() => started = true));
      await tester.pump();

      await tester.tap(find.byType(GameButton));
      await tester.pump();

      expect(started, isTrue);
    });
  });
}
