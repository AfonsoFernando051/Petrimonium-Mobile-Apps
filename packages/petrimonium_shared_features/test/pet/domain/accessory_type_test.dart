import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

void main() {
  test('AccessoryType has exactly the 3 expected slots', () {
    expect(AccessoryType.values, [
      AccessoryType.headwear,
      AccessoryType.eyewear,
      AccessoryType.neckBack,
    ]);
  });
}
