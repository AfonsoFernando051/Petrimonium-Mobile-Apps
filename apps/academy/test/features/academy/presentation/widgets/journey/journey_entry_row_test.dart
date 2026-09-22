import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/academy/presentation/widgets/journey/journey_entry_row.dart';

void main() {
  setUp(() => Translator.currentLanguage = 'pt');

  Widget buildTestable({
    required JourneyRowMark mark,
    String? meta,
    String? badge,
    bool highlighted = false,
    bool indented = false,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: JourneyEntryRow(
          mark: mark,
          title: 'Juros compostos',
          meta: meta,
          badge: badge,
          highlighted: highlighted,
          indented: indented,
          onTap: onTap,
        ),
      ),
    );
  }

  group('JourneyEntryRow', () {
    testWidgets('each state has its own mark, so progress is readable without colour', (tester) async {
      for (final (mark, icon) in [
        (JourneyRowMark.done, Icons.check_rounded),
        (JourneyRowMark.current, Icons.circle),
        (JourneyRowMark.todo, Icons.circle_outlined),
        (JourneyRowMark.locked, Icons.lock_outline_rounded),
      ]) {
        await tester.pumpWidget(buildTestable(mark: mark));
        await tester.pump();
        expect(find.byIcon(icon), findsOneWidget, reason: '$mark should be marked with $icon');
      }
    });

    testWidgets('shows the meta line and the badge when given', (tester) async {
      await tester.pumpWidget(buildTestable(mark: JourneyRowMark.current, meta: '~4 min', badge: 'em andamento'));
      await tester.pump();

      expect(find.text('~4 min'), findsOneWidget);
      expect(find.text('EM ANDAMENTO'), findsOneWidget);
    });

    testWidgets('fires onTap when it has one', (tester) async {
      var taps = 0;
      await tester.pumpWidget(buildTestable(mark: JourneyRowMark.todo, onTap: () => taps++));
      await tester.pump();

      await tester.tap(find.text('Juros compostos'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('a locked row is inert even if a callback is passed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(buildTestable(mark: JourneyRowMark.locked, onTap: () => taps++));
      await tester.pump();

      await tester.tap(find.text('Juros compostos'));
      await tester.pump();

      expect(taps, 0);
    });
  });
}
