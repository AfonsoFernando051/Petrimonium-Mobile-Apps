import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import '../entities/journey_stage.dart';
import 'academy_progress_calculator.dart';
import 'academy_recommendation_service.dart';

/// Turns the flat catalog + the learner's completed lesson ids into the
/// ordered list of [JourneyStage]s the Academy screen draws as a timeline.
///
/// Pure derivation, exactly like [AcademyProgressCalculator]: nothing here is
/// persisted, so a stage's state can never drift from the progress it is
/// derived from.
///
/// The walk order is domain order → school order, the same one
/// [AcademyProgressCalculator.nextLessonToContinue] uses — the timeline and
/// the "what do I continue with" answer must agree, and `school.order` alone
/// would not guarantee that if a future catalog ever made it ambiguous
/// across domains.
class AcademyJourneyBuilder {
  const AcademyJourneyBuilder._();

  static List<JourneyStage> build({required AcademyCatalogSnapshot catalog, required Set<String> completedIds}) {
    final nextLesson = AcademyProgressCalculator.nextLessonToContinue(catalog: catalog, completedIds: completedIds);

    final stages = <JourneyStage>[];
    for (final school in _schoolsInCurriculumOrder(catalog)) {
      stages.add(
        _stageFor(
          catalog: catalog,
          school: school,
          completedIds: completedIds,
          nextLesson: nextLesson,
          position: stages.length + 1,
        ),
      );
    }

    return _withUpNextResolved(stages);
  }

  /// Schools ordered domain-by-domain. A school no domain references is
  /// still appended (by its own `order`) rather than dropped — the journey
  /// must never silently hide content the catalog ships.
  static List<School> _schoolsInCurriculumOrder(AcademyCatalogSnapshot catalog) {
    final ordered = <School>[];
    final seen = <String>{};

    final domains = [...catalog.domains]..sort((a, b) => a.order.compareTo(b.order));
    for (final domain in domains) {
      final schools = domain.schoolIds.map(catalog.schoolById).whereType<School>().toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      for (final school in schools) {
        if (seen.add(school.id)) ordered.add(school);
      }
    }

    final orphans = catalog.schools.where((s) => !seen.contains(s.id)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    ordered.addAll(orphans);

    return ordered;
  }

  static JourneyStage _stageFor({
    required AcademyCatalogSnapshot catalog,
    required School school,
    required Set<String> completedIds,
    required Lesson? nextLesson,
    required int position,
  }) {
    final modules = catalog
        .modulesForSchool(school.id)
        .where((m) => m.contentAvailable)
        .map(
          (module) =>
              _moduleEntryFor(catalog: catalog, module: module, completedIds: completedIds, nextLesson: nextLesson),
        )
        .toList();

    final status = AcademyProgressCalculator.schoolStatus(catalog: catalog, school: school, completedIds: completedIds);
    final holdsNextLesson = modules.any((m) => m.isCurrent);

    return JourneyStage(
      school: school,
      domain: catalog.domainForSchool(school.id),
      position: position,
      state: switch (status) {
        SchoolStatus.comingSoon => JourneyStageState.comingSoon,
        SchoolStatus.locked => JourneyStageState.locked,
        SchoolStatus.completed => JourneyStageState.completed,
        _ => holdsNextLesson ? JourneyStageState.current : JourneyStageState.upcoming,
      },
      completedLessons: modules.fold(0, (sum, m) => sum + m.completedLessons),
      modules: modules,
      missingPrerequisites: status == SchoolStatus.locked
          ? AcademyProgressCalculator.missingSchoolPrerequisiteTitles(
              catalog: catalog,
              school: school,
              completedIds: completedIds,
            )
          : const [],
    );
  }

  static JourneyModuleEntry _moduleEntryFor({
    required AcademyCatalogSnapshot catalog,
    required AcademyModule module,
    required Set<String> completedIds,
    required Lesson? nextLesson,
  }) {
    final lessons = catalog
        .lessonsForModule(module.id)
        .map(
          (lesson) => JourneyLessonEntry(
            lesson: lesson,
            status: AcademyProgressCalculator.lessonStatus(
              catalog: catalog,
              lesson: lesson,
              completedIds: completedIds,
            ),
            isNext: lesson.id == nextLesson?.id,
            estimatedMinutes: estimatedMinutesForLesson(lesson),
          ),
        )
        .toList();

    final status = AcademyProgressCalculator.moduleStatus(catalog: catalog, module: module, completedIds: completedIds);

    return JourneyModuleEntry(
      module: module,
      status: status,
      completedLessons: lessons.where((l) => l.status == LessonStatus.completed).length,
      lessons: lessons,
      isCurrent: lessons.any((l) => l.isNext),
      missingPrerequisites: status == ModuleStatus.locked
          ? AcademyProgressCalculator.missingModulePrerequisiteTitles(
              catalog: catalog,
              module: module,
              completedIds: completedIds,
            )
          : const [],
    );
  }

  /// Promotes the first reachable stage after the current one to
  /// [JourneyStageState.upNext]. A journey with no current stage (everything
  /// available is done) has no "up next" either — promising a next step that
  /// the learner cannot reach yet would be the padlock problem with nicer
  /// wording.
  static List<JourneyStage> _withUpNextResolved(List<JourneyStage> stages) {
    final currentIndex = stages.indexWhere((s) => s.state == JourneyStageState.current);
    if (currentIndex == -1) return stages;

    for (var i = currentIndex + 1; i < stages.length; i++) {
      if (stages[i].state != JourneyStageState.upcoming) continue;
      final stage = stages[i];
      stages[i] = JourneyStage(
        school: stage.school,
        domain: stage.domain,
        position: stage.position,
        state: JourneyStageState.upNext,
        completedLessons: stage.completedLessons,
        modules: stage.modules,
        missingPrerequisites: stage.missingPrerequisites,
      );
      break;
    }
    return stages;
  }

  /// Minute estimate for a single lesson, from its step count — the
  /// per-lesson counterpart of
  /// [AcademyRecommendationService.reviewEstimatedMinutes], sharing its
  /// [kApproxSecondsPerLessonStep] heuristic so the two never quote
  /// different durations for the same content.
  static int estimatedMinutesForLesson(Lesson lesson) {
    if (lesson.steps.isEmpty) return 0;
    final seconds = lesson.steps.length * kApproxSecondsPerLessonStep;
    return (seconds / 60).ceil().clamp(1, 999);
  }
}
