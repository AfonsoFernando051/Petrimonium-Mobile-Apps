import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/features/academy/domain/entities/journey_stage.dart';
import 'package:petrimonium_academy/features/home/domain/services/journey_summary_resolver.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

JourneyStage stage(int position, JourneyStageState state) {
  return JourneyStage(
    school: School(
      id: 'school_$position',
      title: 'School $position',
      description: 'desc',
      iconKey: 'savings_outlined',
      order: position,
      contentAvailable: state != JourneyStageState.comingSoon,
    ),
    domain: null,
    position: position,
    state: state,
    completedLessons: state == JourneyStageState.completed ? 4 : 0,
    modules: const [],
  );
}

List<JourneyStage> journeyOf(List<JourneyStageState> states) {
  return [for (var i = 0; i < states.length; i++) stage(i + 1, states[i])];
}

void main() {
  group('JourneySummaryResolver', () {
    test('returns null for an unloaded journey', () {
      expect(JourneySummaryResolver.resolve(const []), isNull);
    });

    test('focuses the current stage and windows the journey around it', () {
      final journey = journeyOf([
        JourneyStageState.completed,
        JourneyStageState.completed,
        JourneyStageState.completed,
        JourneyStageState.completed,
        JourneyStageState.current,
        JourneyStageState.upNext,
        JourneyStageState.upcoming,
        JourneyStageState.upcoming,
      ]);

      final summary = JourneySummaryResolver.resolve(journey)!;

      expect(summary.focus.position, 5);
      expect(summary.window.map((s) => s.position), [3, 4, 5, 6, 7]);
      expect(summary.hasMoreBefore, isTrue);
      expect(summary.hasMoreAfter, isTrue);
      expect(summary.totalStages, 8);
      expect(summary.completedStages, 4);
      expect(summary.nextStage?.position, 6);
      expect(summary.isComplete, isFalse);
    });

    test('keeps the window inside the journey at its start and its end', () {
      final atStart = JourneySummaryResolver.resolve(
        journeyOf([
          JourneyStageState.current,
          JourneyStageState.upNext,
          JourneyStageState.upcoming,
          JourneyStageState.upcoming,
          JourneyStageState.upcoming,
          JourneyStageState.upcoming,
        ]),
      )!;
      expect(atStart.window.map((s) => s.position), [1, 2, 3, 4, 5]);
      expect(atStart.hasMoreBefore, isFalse);
      expect(atStart.hasMoreAfter, isTrue);

      final atEnd = JourneySummaryResolver.resolve(
        journeyOf([
          JourneyStageState.completed,
          JourneyStageState.completed,
          JourneyStageState.completed,
          JourneyStageState.completed,
          JourneyStageState.completed,
          JourneyStageState.current,
        ]),
      )!;
      expect(atEnd.window.map((s) => s.position), [2, 3, 4, 5, 6]);
      expect(atEnd.hasMoreBefore, isTrue);
      expect(atEnd.hasMoreAfter, isFalse);
    });

    test('windows a journey shorter than the window without padding it', () {
      final summary = JourneySummaryResolver.resolve(journeyOf([JourneyStageState.current, JourneyStageState.upNext]))!;

      expect(summary.window.map((s) => s.position), [1, 2]);
      expect(summary.hasMoreBefore, isFalse);
      expect(summary.hasMoreAfter, isFalse);
    });

    test('falls back to the last completed stage when nothing is current', () {
      final summary = JourneySummaryResolver.resolve(
        journeyOf([JourneyStageState.completed, JourneyStageState.completed, JourneyStageState.comingSoon]),
      )!;

      expect(summary.focus.position, 2);
      expect(summary.isComplete, isTrue);
      expect(summary.nextStage, isNull);
    });

    test('never names an unreachable stage as the next one', () {
      final summary = JourneySummaryResolver.resolve(
        journeyOf([JourneyStageState.current, JourneyStageState.locked, JourneyStageState.comingSoon]),
      )!;

      expect(summary.nextStage, isNull);
      expect(summary.isComplete, isFalse);
    });

    test('a journey that has not been started yet still focuses its first stage', () {
      final summary = JourneySummaryResolver.resolve(
        journeyOf([JourneyStageState.current, JourneyStageState.upNext, JourneyStageState.upcoming]),
      )!;

      expect(summary.focus.position, 1);
      expect(summary.completedStages, 0);
      expect(summary.nextStage?.position, 2);
    });
  });
}
