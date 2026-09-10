import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

void main() {
  group('AcademyModule', () {
    test('constructs with the given fields', () {
      const module = AcademyModule(
        id: 'module_1',
        schoolId: 'school_1',
        title: 'Investor Foundations',
        description: 'Basics',
        iconKey: 'savings_outlined',
        order: 1,
        lessonIds: ['lesson_1', 'lesson_2'],
        prerequisites: ['module_0'],
        contentAvailable: true,
      );

      expect(module.id, 'module_1');
      expect(module.schoolId, 'school_1');
      expect(module.title, 'Investor Foundations');
      expect(module.description, 'Basics');
      expect(module.iconKey, 'savings_outlined');
      expect(module.order, 1);
      expect(module.lessonIds, ['lesson_1', 'lesson_2']);
      expect(module.prerequisites, ['module_0']);
      expect(module.contentAvailable, isTrue);
    });

    test('lessonIds/prerequisites default to empty and contentAvailable defaults to false', () {
      const module = AcademyModule(
        id: 'm',
        schoolId: 's',
        title: 't',
        description: 'd',
        iconKey: 'help_outline',
        order: 0,
      );

      expect(module.lessonIds, isEmpty);
      expect(module.prerequisites, isEmpty);
      expect(module.contentAvailable, isFalse);
    });
  });
}
