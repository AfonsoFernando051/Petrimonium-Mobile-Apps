import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/features/pet/domain/enums/pet_animation_state.dart';

void main() {
  test('has the 9 expected animation states', () {
    expect(PetAnimationState.values, [
      PetAnimationState.idle,
      PetAnimationState.celebrate,
      PetAnimationState.think,
      PetAnimationState.sleep,
      PetAnimationState.victory,
      PetAnimationState.happy,
      PetAnimationState.talking,
      PetAnimationState.listening,
      PetAnimationState.sad,
    ]);
  });

  test('assetKey matches the enum name for every state', () {
    for (final state in PetAnimationState.values) {
      expect(state.assetKey, state.name);
    }
  });
}
