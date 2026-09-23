import 'package:petrimonium_academy/features/academy/domain/entities/journey_stage.dart';
import 'package:petrimonium_academy/features/home/domain/entities/journey_summary.dart';

/// Reduces the full journey to the slice Home shows — same shape as
/// `NextActionResolver`: a pure function over already-loaded state, nothing
/// stored, nothing that can drift from the catalog it was built from.
class JourneySummaryResolver {
  const JourneySummaryResolver._();

  /// How many stages Home's rail draws. Odd, so the learner's own stage
  /// sits in the middle whenever the journey is long enough on both sides.
  static const int kWindowSize = 5;

  /// `null` when the journey isn't loaded yet — Home renders nothing rather
  /// than an empty rail.
  static JourneySummary? resolve(List<JourneyStage> journey, {int windowSize = kWindowSize}) {
    if (journey.isEmpty) return null;

    final focusIndex = _focusIndex(journey);
    final size = windowSize < journey.length ? windowSize : journey.length;
    var start = focusIndex - (size ~/ 2);
    if (start < 0) start = 0;
    if (start + size > journey.length) start = journey.length - size;
    final end = start + size;

    return JourneySummary(
      focus: journey[focusIndex],
      window: journey.sublist(start, end),
      nextStage: _nextStage(journey, focusIndex),
      totalStages: journey.length,
      completedStages: journey.where((stage) => stage.state == JourneyStageState.completed).length,
      hasMoreBefore: start > 0,
      hasMoreAfter: end < journey.length,
      isComplete: journey.every(
        (stage) => stage.state == JourneyStageState.completed || stage.state == JourneyStageState.comingSoon,
      ),
    );
  }

  static int _focusIndex(List<JourneyStage> journey) {
    for (var i = 0; i < journey.length; i++) {
      if (journey[i].state == JourneyStageState.current) return i;
    }
    // No current stage means there is nothing left to continue, so where the
    // learner stands is the last thing they finished — not the first stage
    // of the curriculum.
    for (var i = journey.length - 1; i >= 0; i--) {
      if (journey[i].state == JourneyStageState.completed) return i;
    }
    return 0;
  }

  /// Only a stage the learner can actually reach counts as "next" — a
  /// locked or content-less one would be a promise Home can't keep.
  static JourneyStage? _nextStage(List<JourneyStage> journey, int focusIndex) {
    for (var i = focusIndex + 1; i < journey.length; i++) {
      final state = journey[i].state;
      if (state == JourneyStageState.upNext || state == JourneyStageState.upcoming) return journey[i];
    }
    return null;
  }
}
