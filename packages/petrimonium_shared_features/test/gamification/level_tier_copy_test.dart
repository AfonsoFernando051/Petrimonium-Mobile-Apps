import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

void main() {
  group('levelTierKey', () {
    test('every tier maps to its own key', () {
      final keys = LevelTier.values.map(levelTierKey).toList();
      expect(keys.toSet(), hasLength(LevelTier.values.length), reason: 'two tiers share a key: $keys');
    });

    test('a tier maps to the key the products actually translate', () {
      // Pinned rather than derived: renaming a tier must not silently retarget
      // the copy a user sees for a level they already reached.
      expect(levelTierKey(LevelTier.beginner), SharedStrings.levelTierBeginner);
      expect(levelTierKey(LevelTier.investor), SharedStrings.levelTierInvestor);
      expect(levelTierKey(LevelTier.specialist), SharedStrings.levelTierSpecialist);
    });
  });
}
