import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_wallet/features/onboarding/data/models/investor_profile_goal_enum.dart';

void main() {
  group('InvestorProfileGoalEnumDisplay', () {
    test('every value has a non-empty label', () {
      for (final goal in InvestorProfileGoalEnum.values) {
        expect(goal.label, isNotEmpty);
      }
    });

    test('labels are unique across all goals', () {
      final labels = InvestorProfileGoalEnum.values.map((g) => g.label).toSet();
      expect(labels.length, InvestorProfileGoalEnum.values.length);
    });
  });

  group('InvestorProfileGoalEnumDisplay.wireValue', () {
    test('matches the backend FinancialGoal enum constant for every value', () {
      expect(InvestorProfileGoalEnum.emergencyFund.wireValue, 'EMERGENCY_FUND');
      expect(InvestorProfileGoalEnum.getOutOfDebt.wireValue, 'GET_OUT_OF_DEBT');
      expect(InvestorProfileGoalEnum.buyImportantThing.wireValue, 'BUY_IMPORTANT_THING');
      expect(InvestorProfileGoalEnum.investWithConfidence.wireValue, 'INVEST_WITH_CONFIDENCE');
      expect(InvestorProfileGoalEnum.justWantToLearn.wireValue, 'JUST_WANT_TO_LEARN');
    });

    test('every value has a unique wire value', () {
      final wireValues = InvestorProfileGoalEnum.values.map((g) => g.wireValue).toSet();
      expect(wireValues.length, InvestorProfileGoalEnum.values.length);
    });
  });
}
