import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

void main() {
  group('OptionModel.fromJson', () {
    test('parses id and text from json', () {
      final option = OptionModel.fromJson(const {'id': 'q1_a', 'text': 'Sim'});

      expect(option.id, 'q1_a');
      expect(option.text, 'Sim');
    });
  });

  test('const constructor sets fields directly', () {
    const option = OptionModel(id: 'q1_b', text: 'Não');

    expect(option.id, 'q1_b');
    expect(option.text, 'Não');
  });
}
