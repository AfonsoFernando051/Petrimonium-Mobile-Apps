import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/features/academy/domain/entities/journey_stage.dart';
import 'package:petrimonium_academy/features/academy/domain/services/academy_journey_builder.dart';
import 'package:petrimonium_academy/features/academy/domain/services/academy_progress_calculator.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

/// A curriculum with enough shape to exercise every stage state at once:
/// two domains, four schools (one a `comingSoon` placeholder, one gated
/// behind a prerequisite), and modules whose lessons can be completed in
/// curriculum order.
AcademyCatalogSnapshot _catalog() {
  return const AcademyCatalogSnapshot(
    domains: [
      AcademyDomain(
        id: 'd1',
        title: 'Domain 1',
        description: '',
        iconKey: 'savings_outlined',
        order: 1,
        schoolIds: ['s1', 's2', 'soon'],
      ),
      AcademyDomain(
        id: 'd2',
        title: 'Domain 2',
        description: '',
        iconKey: 'savings_outlined',
        order: 2,
        schoolIds: ['s3'],
      ),
    ],
    schools: [
      School(
        id: 's1',
        title: 'School 1',
        description: '',
        iconKey: 'savings_outlined',
        order: 1,
        contentAvailable: true,
      ),
      School(
        id: 's2',
        title: 'School 2',
        description: '',
        iconKey: 'savings_outlined',
        order: 2,
        contentAvailable: true,
      ),
      School(id: 'soon', title: 'Coming Soon', description: '', iconKey: 'savings_outlined', order: 3),
      School(
        id: 's3',
        title: 'School 3',
        description: '',
        iconKey: 'savings_outlined',
        order: 4,
        prerequisites: ['s2'],
        contentAvailable: true,
      ),
    ],
    modules: [
      AcademyModule(
        id: 'm1',
        schoolId: 's1',
        title: 'Module 1',
        description: '',
        iconKey: 'savings_outlined',
        order: 1,
        lessonIds: ['l1', 'l2'],
        contentAvailable: true,
      ),
      AcademyModule(
        id: 'm2',
        schoolId: 's2',
        title: 'Module 2',
        description: '',
        iconKey: 'savings_outlined',
        order: 1,
        lessonIds: ['l3', 'l4'],
        contentAvailable: true,
      ),
      AcademyModule(
        id: 'm3',
        schoolId: 's3',
        title: 'Module 3',
        description: '',
        iconKey: 'savings_outlined',
        order: 1,
        lessonIds: ['l5'],
        contentAvailable: true,
      ),
    ],
    lessons: [
      Lesson(id: 'l1', moduleId: 'm1', title: 'Lesson 1', order: 1, xpReward: 10, steps: _twoSteps),
      Lesson(id: 'l2', moduleId: 'm1', title: 'Lesson 2', order: 2, xpReward: 10, steps: _twoSteps),
      Lesson(id: 'l3', moduleId: 'm2', title: 'Lesson 3', order: 1, xpReward: 10, steps: _twoSteps),
      Lesson(id: 'l4', moduleId: 'm2', title: 'Lesson 4', order: 2, xpReward: 10, steps: _twoSteps),
      Lesson(id: 'l5', moduleId: 'm3', title: 'Lesson 5', order: 1, xpReward: 10, steps: _twoSteps),
    ],
  );
}

const _twoSteps = [
  ExplanationStep(title: 'a', body: 'b'),
  SummaryStep(title: 'c', takeaways: ['d']),
];

JourneyStage _stage(List<JourneyStage> journey, String schoolId) => journey.firstWhere((s) => s.school.id == schoolId);

void main() {
  group('AcademyJourneyBuilder', () {
    test('orders stages by domain order, then school order, numbered from 1', () {
      final journey = AcademyJourneyBuilder.build(catalog: _catalog(), completedIds: const {});

      expect(journey.map((s) => s.school.id).toList(), ['s1', 's2', 'soon', 's3']);
      expect(journey.map((s) => s.position).toList(), [1, 2, 3, 4]);
    });

    test('appends a school no domain references instead of dropping it', () {
      final base = _catalog();
      final catalog = AcademyCatalogSnapshot(
        domains: base.domains,
        schools: [
          ...base.schools,
          const School(
            id: 'orphan',
            title: 'Orphan',
            description: '',
            iconKey: 'savings_outlined',
            order: 99,
            contentAvailable: true,
          ),
        ],
        modules: base.modules,
        lessons: base.lessons,
      );

      final journey = AcademyJourneyBuilder.build(catalog: catalog, completedIds: const {});

      expect(journey.last.school.id, 'orphan');
    });

    test('marks the school holding the next lesson as current, and the one after it as up next', () {
      final journey = AcademyJourneyBuilder.build(catalog: _catalog(), completedIds: const {});

      expect(_stage(journey, 's1').state, JourneyStageState.current);
      expect(_stage(journey, 's2').state, JourneyStageState.upNext);
    });

    test('a finished school collapses to completed and stops being current', () {
      final journey = AcademyJourneyBuilder.build(catalog: _catalog(), completedIds: const {'l1', 'l2'});

      expect(_stage(journey, 's1').state, JourneyStageState.completed);
      expect(_stage(journey, 's1').completedLessons, 2);
      expect(_stage(journey, 's2').state, JourneyStageState.current);
    });

    test('a school with no real content is a coming-soon stage with no modules', () {
      final journey = AcademyJourneyBuilder.build(catalog: _catalog(), completedIds: const {});

      expect(_stage(journey, 'soon').state, JourneyStageState.comingSoon);
      expect(_stage(journey, 'soon').modules, isEmpty);
    });

    test('a school gated on an unmet prerequisite names it instead of just locking', () {
      final journey = AcademyJourneyBuilder.build(catalog: _catalog(), completedIds: const {});

      expect(_stage(journey, 's3').state, JourneyStageState.locked);
      expect(_stage(journey, 's3').missingPrerequisites, ['School 2']);
    });

    test('a locked stage is never promoted to up next', () {
      // Every reachable school but the gated one is done, so the only stage
      // after `current` is `s3` — which is locked, and must stay so.
      final journey = AcademyJourneyBuilder.build(catalog: _catalog(), completedIds: const {'l1', 'l2', 'l3'});

      expect(_stage(journey, 's2').state, JourneyStageState.current);
      expect(_stage(journey, 's3').state, JourneyStageState.locked);
      expect(journey.where((s) => s.state == JourneyStageState.upNext), isEmpty);
    });

    test('nothing is current or up next once every reachable lesson is done', () {
      final journey = AcademyJourneyBuilder.build(
        catalog: _catalog(),
        completedIds: const {'l1', 'l2', 'l3', 'l4', 'l5'},
      );

      expect(journey.where((s) => s.state == JourneyStageState.current), isEmpty);
      expect(journey.where((s) => s.state == JourneyStageState.upNext), isEmpty);
    });

    test('only the module holding the next lesson is current, and only that lesson is flagged next', () {
      final journey = AcademyJourneyBuilder.build(catalog: _catalog(), completedIds: const {'l1'});
      final stage = _stage(journey, 's1');

      expect(stage.currentModule?.module.id, 'm1');
      expect(stage.nextLesson?.id, 'l2');
      expect(stage.modules.single.lessons.where((l) => l.isNext).map((l) => l.lesson.id), ['l2']);
      expect(stage.modules.single.completedLessons, 1);
      expect(stage.modules.single.status, ModuleStatus.inProgress);
    });

    test('lesson status and progress come from the real completion set', () {
      final journey = AcademyJourneyBuilder.build(catalog: _catalog(), completedIds: const {'l1'});
      final lessons = _stage(journey, 's1').modules.single.lessons;

      expect(lessons.map((l) => l.status).toList(), [LessonStatus.completed, LessonStatus.available]);
      expect(_stage(journey, 's1').progress, 0.5);
    });

    test('estimated minutes come from the lesson step count, not a fixed value', () {
      const oneStep = Lesson(
        id: 'x',
        moduleId: 'm1',
        title: 'x',
        order: 1,
        xpReward: 1,
        steps: [ExplanationStep(title: 'a', body: 'b')],
      );
      const nineSteps = Lesson(
        id: 'y',
        moduleId: 'm1',
        title: 'y',
        order: 1,
        xpReward: 1,
        steps: [
          ExplanationStep(title: 'a', body: 'b'),
          ExplanationStep(title: 'a', body: 'b'),
          ExplanationStep(title: 'a', body: 'b'),
          ExplanationStep(title: 'a', body: 'b'),
          ExplanationStep(title: 'a', body: 'b'),
          ExplanationStep(title: 'a', body: 'b'),
          ExplanationStep(title: 'a', body: 'b'),
          ExplanationStep(title: 'a', body: 'b'),
          ExplanationStep(title: 'a', body: 'b'),
        ],
      );

      expect(AcademyJourneyBuilder.estimatedMinutesForLesson(oneStep), 1);
      expect(AcademyJourneyBuilder.estimatedMinutesForLesson(nineSteps), 6);
      expect(
        AcademyJourneyBuilder.estimatedMinutesForLesson(
          const Lesson(id: 'z', moduleId: 'm1', title: 'z', order: 1, xpReward: 1, steps: []),
        ),
        0,
      );
    });
  });
}
