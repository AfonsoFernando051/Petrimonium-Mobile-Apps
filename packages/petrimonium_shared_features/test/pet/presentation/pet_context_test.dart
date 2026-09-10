import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

void main() {
  test('has exactly the 5 real top-level destinations', () {
    expect(PetContext.values, [
      PetContext.home,
      PetContext.academy,
      PetContext.portfolio,
      PetContext.mentor,
      PetContext.profile,
    ]);
  });
}
