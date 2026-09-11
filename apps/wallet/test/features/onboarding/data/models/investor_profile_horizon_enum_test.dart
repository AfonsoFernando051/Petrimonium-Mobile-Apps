import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_wallet/features/onboarding/data/models/investor_profile_horizon_enum.dart';

void main() {
  group('InvestorProfileHorizonEnumDisplay', () {
    test('every value has a non-empty label', () {
      for (final horizon in InvestorProfileHorizonEnum.values) {
        expect(horizon.label, isNotEmpty);
      }
    });

    test('labels are unique across all horizons', () {
      final labels = InvestorProfileHorizonEnum.values.map((h) => h.label).toSet();
      expect(labels.length, InvestorProfileHorizonEnum.values.length);
    });
  });

  group('InvestorProfileHorizonEnumDisplay.wireValue', () {
    test('matches the backend InvestmentHorizon enum constant for every value', () {
      expect(InvestorProfileHorizonEnum.upToOneYear.wireValue, 'UP_TO_ONE_YEAR');
      expect(InvestorProfileHorizonEnum.oneToFiveYears.wireValue, 'ONE_TO_FIVE_YEARS');
      expect(InvestorProfileHorizonEnum.moreThanFiveYears.wireValue, 'MORE_THAN_FIVE_YEARS');
      expect(InvestorProfileHorizonEnum.notSureYet.wireValue, 'NOT_SURE_YET');
    });

    test('every value has a unique wire value', () {
      final wireValues = InvestorProfileHorizonEnum.values.map((h) => h.wireValue).toSet();
      expect(wireValues.length, InvestorProfileHorizonEnum.values.length);
    });
  });
}
