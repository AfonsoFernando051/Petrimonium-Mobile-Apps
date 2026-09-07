import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

void main() {
  test('AppMotion.pageTransition is 350ms', () {
    expect(AppMotion.pageTransition, const Duration(milliseconds: 350));
  });
}
