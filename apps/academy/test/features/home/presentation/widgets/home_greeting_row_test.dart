import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/home/presentation/widgets/home_greeting_row.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  Widget buildTestable({String? userName, int? streakDays, bool isFirstSession = false}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: HomeGreetingRow(userName: userName, streakDays: streakDays, isFirstSession: isFirstSession),
      ),
    );
  }

  group('HomeGreetingRow', () {
    testWidgets('shows a generic greeting when no name is known', (tester) async {
      await tester.pumpWidget(buildTestable());

      expect(find.text('Bem-vindo de volta'), findsOneWidget);
    });

    testWidgets('shows the real name when known', (tester) async {
      await tester.pumpWidget(buildTestable(userName: 'Camila'));

      expect(find.text('Bem-vindo de volta, Camila'), findsOneWidget);
    });

    // Home used to open with "Bem-vindo de volta" seconds after the user
    // finished signing up, because the row only ever chose between the
    // with-name and without-name flavours of the returning greeting.
    testWidgets('does not say "de volta" on the very first session', (tester) async {
      await tester.pumpWidget(buildTestable(isFirstSession: true));

      expect(find.text('Bem-vindo'), findsOneWidget);
      expect(find.text('Bem-vindo de volta'), findsNothing);
    });

    testWidgets('greets a first-time user by name when it knows it', (tester) async {
      await tester.pumpWidget(buildTestable(userName: 'Camila', isFirstSession: true));

      expect(find.text('Bem-vindo, Camila'), findsOneWidget);
      expect(find.text('Bem-vindo de volta, Camila'), findsNothing);
    });

    testWidgets('goes back to "de volta" from the second session on', (tester) async {
      await tester.pumpWidget(buildTestable(userName: 'Camila'));

      expect(find.text('Bem-vindo de volta, Camila'), findsOneWidget);
    });

    testWidgets('shows the streak badge when streakDays is positive', (tester) async {
      await tester.pumpWidget(buildTestable(streakDays: 3));

      expect(find.text('3 dias'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
    });

    testWidgets('hides the streak badge at 0 or null', (tester) async {
      await tester.pumpWidget(buildTestable(streakDays: 0));
      expect(find.text('🔥'), findsNothing);

      await tester.pumpWidget(buildTestable(streakDays: null));
      expect(find.text('🔥'), findsNothing);
    });
  });
}
