import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/features/academy/domain/entities/academy_domain.dart';

void main() {
  group('AcademyDomain', () {
    test('constructs with the given fields', () {
      const domain = AcademyDomain(
        id: 'investments',
        title: 'Investimentos',
        description: 'Learn to invest',
        iconKey: 'show_chart',
        order: 1,
        schoolIds: ['fixed_income', 'stocks'],
      );

      expect(domain.id, 'investments');
      expect(domain.title, 'Investimentos');
      expect(domain.description, 'Learn to invest');
      expect(domain.iconKey, 'show_chart');
      expect(domain.order, 1);
      expect(domain.schoolIds, ['fixed_income', 'stocks']);
    });

    test('schoolIds defaults to an empty list when omitted', () {
      const domain = AcademyDomain(id: 'x', title: 'x', description: 'x', iconKey: 'help_outline', order: 0);

      expect(domain.schoolIds, isEmpty);
    });
  });
}
