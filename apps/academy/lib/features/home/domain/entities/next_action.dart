import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

/// Home's single, ranked answer to "what should I do now" — see
/// `NextActionResolver`. Exactly one variant is ever active at a time; the
/// screen renders whichever is current as its one primary CTA rather than
/// juggling several competing cards for that slot.
sealed class NextAction {
  const NextAction();
}

/// The default, most common state: resume the learner's real next lesson.
/// This remains the product's strongest CTA when nothing more urgent is
/// happening (`docs/ACADEMY_ENGINE.md` §5 — continuing is always offered
/// first) — [NextActionResolver] only ranks something above it when there's
/// a genuine, time-bound reason to.
class ContinueLessonAction extends NextAction {
  final Lesson lesson;

  /// Resolved by the caller (which already has the loaded catalog in
  /// scope) — `null` while the catalog is still loading.
  final String? moduleTitle;

  /// The module's total lesson count and how many of them are already
  /// completed — `null` while that isn't known yet. Powers the "N aulas" /
  /// progress bar shown alongside [moduleTitle].
  final int? moduleLessonCount;
  final int? moduleCompletedCount;

  /// The lesson's 1-based place inside its module — `null` while the
  /// catalog isn't loaded. Powers the "Aula 7 de 10" line, which says where
  /// the learner is far more concretely than a bare progress bar.
  final int? lessonPosition;

  /// Minute estimate for this lesson, derived from its step count by the
  /// caller (`AcademyJourneyBuilder.estimatedMinutesForLesson`) — `0` when
  /// the lesson has no steps to estimate from, never a made-up default.
  final int? estimatedMinutes;

  /// The user's own onboarding goal, already resolved to display text
  /// (`PetGoalEnum.label`) by the caller — `null` while it hasn't loaded.
  final String? goalLabel;

  const ContinueLessonAction({
    required this.lesson,
    this.moduleTitle,
    this.moduleLessonCount,
    this.moduleCompletedCount,
    this.lessonPosition,
    this.estimatedMinutes,
    this.goalLabel,
  });
}

/// A real mission is exactly one lesson completion away from finishing —
/// worth surfacing above the default continue-lesson action since it's a
/// genuine, time-bound (daily/weekly) opportunity that would otherwise stay
/// invisible on Home (missions render only on the Portfolio tab).
class CompleteMissionAction extends NextAction {
  final MissionStatus mission;

  const CompleteMissionAction(this.mission);
}

/// Every currently-available lesson has been completed — there's genuinely
/// nothing left to continue. Distinct from a loading/error state.
class AllLessonsCompleteAction extends NextAction {
  const AllLessonsCompleteAction();
}
