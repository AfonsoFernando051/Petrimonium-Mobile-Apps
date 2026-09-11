import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_wallet/features/onboarding/data/models/investor_profile_experience_enum.dart';

void main() {
  group('InvestorProfileExperienceEnumDisplay', () {
    test('every value has a non-empty label', () {
      for (final level in InvestorProfileExperienceEnum.values) {
        expect(level.label, isNotEmpty);
      }
    });

    test('labels are unique across all levels', () {
      final labels = InvestorProfileExperienceEnum.values.map((e) => e.label).toSet();
      expect(labels.length, InvestorProfileExperienceEnum.values.length);
    });
  });

  group('InvestorProfileExperienceEnumDisplay.wireValue', () {
    test('matches the backend ExperienceLevel enum constant for every value', () {
      expect(InvestorProfileExperienceEnum.novice.wireValue, 'NOVICE');
      expect(InvestorProfileExperienceEnum.curious.wireValue, 'CURIOUS');
      expect(InvestorProfileExperienceEnum.practitioner.wireValue, 'PRACTITIONER');
    });

    test('every value has a unique wire value', () {
      final wireValues = InvestorProfileExperienceEnum.values.map((e) => e.wireValue).toSet();
      expect(wireValues.length, InvestorProfileExperienceEnum.values.length);
    });
  });
}
