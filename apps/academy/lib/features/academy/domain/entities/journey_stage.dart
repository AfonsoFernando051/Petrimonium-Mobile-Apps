import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import '../services/academy_progress_calculator.dart';

/// Where one [JourneyStage] sits relative to the learner's position on the
/// journey. Deliberately richer than [SchoolStatus]: that answers "is this
/// school done/locked", this answers "is this the step the learner is on,
/// the one right after it, or one further ahead" — which is what decides how
/// much of the stage the Academy screen unfolds.
enum JourneyStageState {
  /// Every content-available lesson of the school is completed.
  completed,

  /// Holds the lesson the learner would continue with right now. At most one
  /// stage per journey is ever in this state.
  current,

  /// The first reachable stage after [current] — the "up next" promise.
  upNext,

  /// Reachable, but further ahead than [upNext].
  upcoming,

  /// Blocked by an unmet school-level prerequisite. [JourneyStage
  /// .missingPrerequisites] names which, so the UI never shows a bare
  /// padlock.
  locked,

  /// Curriculum placeholder with no real content yet.
  comingSoon,
}

/// One lesson inside a [JourneyModuleEntry], with everything the journey
/// timeline needs to draw its row.
class JourneyLessonEntry {
  const JourneyLessonEntry({
    required this.lesson,
    required this.status,
    required this.isNext,
    required this.estimatedMinutes,
  });

  final Lesson lesson;
  final LessonStatus status;

  /// Whether this is the single lesson `AcademyController.nextLesson` points
  /// at — the one the journey highlights as "em andamento".
  final bool isNext;

  /// Rounded minute estimate derived from the lesson's step count (the same
  /// `kApproxSecondsPerLessonStep` heuristic the review queue already uses).
  /// The curriculum carries no authored duration, so this is the only honest
  /// number available — never a fixed per-lesson value.
  final int estimatedMinutes;
}

/// One module inside a [JourneyStage].
class JourneyModuleEntry {
  const JourneyModuleEntry({
    required this.module,
    required this.status,
    required this.completedLessons,
    required this.lessons,
    required this.isCurrent,
    this.missingPrerequisites = const [],
  });

  final AcademyModule module;
  final ModuleStatus status;
  final int completedLessons;

  /// Every lesson of the module, in curriculum order. The timeline only
  /// unfolds them for [isCurrent]; the rest of the time they stay behind the
  /// module row's own tap target (`ModuleDetailScreen`).
  final List<JourneyLessonEntry> lessons;

  /// Whether this module holds the journey's next lesson.
  final bool isCurrent;

  /// Titles of the prerequisite modules still missing — only non-empty when
  /// [status] is [ModuleStatus.locked].
  final List<String> missingPrerequisites;

  int get totalLessons => lessons.length;
}

/// One step of the Academy learning journey: a [School], its place in the
/// curriculum order, and how far the learner has walked through it.
///
/// A school (not a module, not a domain) is the journey's unit because it is
/// the level the curriculum already orders end-to-end and gates with
/// prerequisites — `school.order` is the spine the timeline is drawn along.
class JourneyStage {
  const JourneyStage({
    required this.school,
    required this.domain,
    required this.position,
    required this.state,
    required this.completedLessons,
    required this.modules,
    this.missingPrerequisites = const [],
  });

  final School school;

  /// The domain this school belongs to, when the catalog groups it under one
  /// — used as the timeline's chapter heading, not as a level of its own.
  final AcademyDomain? domain;

  /// 1-based index on the journey, shown inside the timeline node.
  final int position;

  final JourneyStageState state;
  final int completedLessons;

  /// The school's content-available modules, in curriculum order.
  final List<JourneyModuleEntry> modules;

  /// Titles of the prerequisite schools still missing — only non-empty when
  /// [state] is [JourneyStageState.locked].
  final List<String> missingPrerequisites;

  int get totalLessons => modules.fold(0, (sum, m) => sum + m.totalLessons);

  double get progress => totalLessons == 0 ? 0 : completedLessons / totalLessons;

  /// The module holding the journey's next lesson, if this is the current
  /// stage.
  JourneyModuleEntry? get currentModule {
    for (final module in modules) {
      if (module.isCurrent) return module;
    }
    return null;
  }

  /// The lesson the "Continuar aula" CTA opens — `null` on any stage that
  /// isn't [JourneyStageState.current].
  Lesson? get nextLesson {
    for (final entry in currentModule?.lessons ?? const <JourneyLessonEntry>[]) {
      if (entry.isNext) return entry.lesson;
    }
    return null;
  }
}
