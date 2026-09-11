import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/features/pet/data/models/experience_level_enum.dart';

void main() {
  group('ExperienceLevelEnumDisplay', () {
    test('every value has a non-empty label, description and emoji', () {
      for (final level in ExperienceLevelEnum.values) {
        expect(level.label, isNotEmpty);
        expect(level.description, isNotEmpty);
        expect(level.emoji, isNotEmpty);
      }
    });

    test('label distinguishes each level', () {
      expect(ExperienceLevelEnum.novice.label, 'Iniciante');
      expect(ExperienceLevelEnum.curious.label, 'Curioso');
      expect(ExperienceLevelEnum.practitioner.label, 'Praticante');
    });
  });

  group('ExperienceLevelEnumDisplay.fromName', () {
    test('resolves a matching name back to its enum value', () {
      for (final level in ExperienceLevelEnum.values) {
        expect(ExperienceLevelEnumDisplay.fromName(level.name), level);
      }
    });

    test('falls back to novice for an unknown or null name', () {
      expect(ExperienceLevelEnumDisplay.fromName('bogus'), ExperienceLevelEnum.novice);
      expect(ExperienceLevelEnumDisplay.fromName(null), ExperienceLevelEnum.novice);
    });
  });

  group('ExperienceLevelEnumDisplay.wireValue', () {
    test('matches the backend ExperienceLevel enum constant for every value', () {
      expect(ExperienceLevelEnum.novice.wireValue, 'NOVICE');
      expect(ExperienceLevelEnum.curious.wireValue, 'CURIOUS');
      expect(ExperienceLevelEnum.practitioner.wireValue, 'PRACTITIONER');
    });

    test('every value has a unique wire value', () {
      final wireValues = ExperienceLevelEnum.values.map((e) => e.wireValue).toSet();
      expect(wireValues.length, ExperienceLevelEnum.values.length);
    });
  });
}
