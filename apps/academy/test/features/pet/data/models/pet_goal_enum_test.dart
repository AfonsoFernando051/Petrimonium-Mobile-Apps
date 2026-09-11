import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/features/pet/data/models/pet_goal_enum.dart';

void main() {
  group('PetGoalEnumDisplay', () {
    test('every value has a non-empty label, emoji and icon', () {
      for (final goal in PetGoalEnum.values) {
        expect(goal.label, isNotEmpty);
        expect(goal.emoji, isNotEmpty);
        expect(goal.icon, isNotNull);
      }
    });

    test('labels are unique across all goals', () {
      final labels = PetGoalEnum.values.map((g) => g.label).toSet();
      expect(labels.length, PetGoalEnum.values.length);
    });
  });

  group('PetGoalEnumDisplay.fromName', () {
    test('resolves a matching name back to its enum value', () {
      for (final goal in PetGoalEnum.values) {
        expect(PetGoalEnumDisplay.fromName(goal.name), goal);
      }
    });

    test('falls back to investWithConfidence for an unknown or null name', () {
      expect(PetGoalEnumDisplay.fromName('bogus'), PetGoalEnum.investWithConfidence);
      expect(PetGoalEnumDisplay.fromName(null), PetGoalEnum.investWithConfidence);
    });
  });

  group('PetGoalEnumDisplay.wireValue', () {
    test('matches the backend FinancialGoal enum constant for every value', () {
      expect(PetGoalEnum.emergencyFund.wireValue, 'EMERGENCY_FUND');
      expect(PetGoalEnum.getOutOfDebt.wireValue, 'GET_OUT_OF_DEBT');
      expect(PetGoalEnum.buyImportantThing.wireValue, 'BUY_IMPORTANT_THING');
      expect(PetGoalEnum.investWithConfidence.wireValue, 'INVEST_WITH_CONFIDENCE');
      expect(PetGoalEnum.justWantToLearn.wireValue, 'JUST_WANT_TO_LEARN');
    });

    test('every value has a unique wire value', () {
      final wireValues = PetGoalEnum.values.map((g) => g.wireValue).toSet();
      expect(wireValues.length, PetGoalEnum.values.length);
    });
  });
}
