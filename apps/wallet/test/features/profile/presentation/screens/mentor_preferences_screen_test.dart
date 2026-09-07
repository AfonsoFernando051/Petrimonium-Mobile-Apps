import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/core/theme/app_theme.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/game_button.dart';
import 'package:petrimonium/features/pet/data/models/investment_horizon_enum.dart';
import 'package:petrimonium/features/pet/data/models/pet_goal_enum.dart';
import 'package:petrimonium/features/pet/data/repositories/pet_preferences_repository.dart';
import 'package:petrimonium/features/profile/presentation/screens/mentor_preferences_screen.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});
    DI.petPreferencesRepository = PetPreferencesRepository();
  });

  Widget buildTestable() {
    return MaterialApp(theme: AppTheme.dark, home: const MentorPreferencesScreen());
  }

  group('MentorPreferencesScreen', () {
    testWidgets('renders every goal and horizon option, defaulting to the saved (or default) values', (tester) async {
      // The 7 goal + 3 horizon options overflow the default 600px test
      // viewport — a real (non-lazy-friendly) ListView won't mount anything
      // below the fold without scrolling, so widen the surface instead.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 3000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestable());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      for (final goal in PetGoalEnum.values) {
        expect(find.text(goal.label), findsOneWidget);
      }
      for (final horizon in InvestmentHorizonEnum.values) {
        expect(find.text(horizon.label), findsOneWidget);
      }
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2)); // buildWealth + mediumTerm defaults
    });

    testWidgets('selecting a different goal and saving persists it', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 3000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestable());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text(PetGoalEnum.travel.label));
      await tester.pump();

      await tester.tap(find.byType(GameButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(await DI.petPreferencesRepository.loadGoal(), PetGoalEnum.travel);
    });
  });
}
