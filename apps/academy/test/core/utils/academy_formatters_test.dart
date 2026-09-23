import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/utils/academy_formatters.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';

void main() {
  setUp(() => Translator.currentLanguage = 'pt');

  test('values that round to zero have no negative or positive sign', () {
    for (final value in [-0.00001, -0.0, 0.0, 0.00001]) {
      expect(AcademyFormatters.currency(value), 'R\$ 0,00');
      expect(AcademyFormatters.percent(value), '0,00%');
    }
    expect(AcademyFormatters.percent(-0.01), '-0,01%');
    expect(AcademyFormatters.percent(0.01), '+0,01%');
  });
}
