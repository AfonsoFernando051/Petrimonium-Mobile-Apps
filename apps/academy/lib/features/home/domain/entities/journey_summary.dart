import 'package:petrimonium_academy/features/academy/domain/entities/journey_stage.dart';

/// Home's compact read of the learning journey: where the learner stands,
/// the handful of stages around that position, and what comes right after.
///
/// This is the progressive-disclosure boundary between Home and Academia:
/// Home answers "where am I and what is next", the Academia tab owns the
/// full timeline (19 schools today). Nothing here ever carries the whole
/// journey — [window] is deliberately a slice, and [hasMoreBefore]/
/// [hasMoreAfter] are what let the rail admit that it is one.
class JourneySummary {
  const JourneySummary({
    required this.focus,
    required this.window,
    required this.nextStage,
    required this.totalStages,
    required this.completedStages,
    required this.hasMoreBefore,
    required this.hasMoreAfter,
    required this.isComplete,
  });

  /// The stage the learner is on — or, once there is nothing left to
  /// continue, the last one they finished.
  final JourneyStage focus;

  /// The stages drawn on Home's rail, in curriculum order, always
  /// containing [focus].
  final List<JourneyStage> window;

  /// The next stage with real, reachable content after [focus] — `null`
  /// when everything ahead is locked or still unwritten, so Home never
  /// promises a stage the learner cannot get to.
  final JourneyStage? nextStage;

  final int totalStages;
  final int completedStages;

  /// Whether [window] omits stages before/after it — the rail draws a faded
  /// stub instead of pretending the journey starts or ends there.
  final bool hasMoreBefore;
  final bool hasMoreAfter;

  /// Every stage with content is finished. Distinct from "no stage is
  /// current" alone, which is also true of a journey that is entirely
  /// locked.
  final bool isComplete;
}
