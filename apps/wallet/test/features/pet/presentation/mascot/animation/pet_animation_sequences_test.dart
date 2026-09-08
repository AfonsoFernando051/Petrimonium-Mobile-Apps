import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_wallet/features/pet/domain/enums/pet_animation_state.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/animation/pet_animation_sequences.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/animation/pet_pose.dart';

/// [PetMotionSequence.animatable] is pure math — no [AnimationController],
/// no ticker, no widget tree needed to assert on its shape. That is the
/// whole point of keeping `PetAnimationSequences` free of any Flutter
/// widget/state dependency: every sequence's waypoints can be checked
/// directly.
void main() {
  const loopStates = [
    PetAnimationState.idle,
    PetAnimationState.think,
    PetAnimationState.sleep,
    PetAnimationState.listening,
    PetAnimationState.talking,
    PetAnimationState.sad,
  ];

  const reactionStates = [
    PetAnimationState.happy,
    PetAnimationState.celebrate,
    PetAnimationState.victory,
  ];

  test('sequenceFor covers every PetAnimationState exactly once', () {
    for (final state in PetAnimationState.values) {
      // Throws if a state has no mapping; the switch in sequenceFor is
      // exhaustive, so this only really guards against the two lists above
      // drifting out of sync with the enum.
      expect(() => PetAnimationSequences.sequenceFor(state), returnsNormally);
    }
    expect(loopStates.length + reactionStates.length, PetAnimationState.values.length);
  });

  group('loop sequences', () {
    for (final state in loopStates) {
      test('$state is tagged as a loop and begins where it ends (seamless repeat)', () {
        final sequence = PetAnimationSequences.sequenceFor(state);
        expect(sequence.kind, PetSequenceKind.loop);

        final start = sequence.animatable.transform(0.0);
        final end = sequence.animatable.transform(1.0);
        expect(start, end, reason: '$state must not pop when AnimationController.repeat() wraps 1.0 -> 0.0');
      });
    }
  });

  group('reaction sequences', () {
    for (final state in reactionStates) {
      test('$state is tagged as a reaction and both begins and ends at rest', () {
        final sequence = PetAnimationSequences.sequenceFor(state);
        expect(sequence.kind, PetSequenceKind.reaction);

        expect(sequence.animatable.transform(0.0), PetPose.rest);
        expect(sequence.animatable.transform(1.0), PetPose.rest);
      });
    }

    test('reactions actually move away from rest at their midpoint', () {
      // Guards against a reaction that's accidentally a no-op end to end
      // (e.g. every waypoint collapsed back to PetPose.rest by a typo).
      for (final state in reactionStates) {
        final sequence = PetAnimationSequences.sequenceFor(state);
        final mid = sequence.animatable.transform(0.5);
        expect(mid, isNot(PetPose.rest), reason: '$state should be mid-motion at t=0.5');
      }
    });

    test('victory is the largest of the three reactions', () {
      double peakDisplacement(PetAnimationState state) {
        final animatable = PetAnimationSequences.sequenceFor(state).animatable;
        var peak = 0.0;
        for (var i = 0; i <= 20; i++) {
          final pose = animatable.transform(i / 20);
          peak = [peak, pose.dy.abs(), (pose.scaleX - 1).abs(), (pose.scaleY - 1).abs()].reduce(
            (a, b) => a > b ? a : b,
          );
        }
        return peak;
      }

      final victoryPeak = peakDisplacement(PetAnimationState.victory);
      final celebratePeak = peakDisplacement(PetAnimationState.celebrate);
      final happyPeak = peakDisplacement(PetAnimationState.happy);

      expect(victoryPeak, greaterThan(celebratePeak));
      expect(celebratePeak, greaterThan(happyPeak));
    });
  });

  test('idle stays within a small, fixed displacement budget', () {
    // Not a comparison against the other loops — think's amplitude is
    // legitimately rotation-dominated, and talking is deliberately tight —
    // just a coarse, absolute guard against idle accidentally becoming
    // flashy, per the product brief's "must be nearly subliminal."
    final animatable = PetAnimationSequences.idle.animatable;
    for (var i = 0; i <= 40; i++) {
      final pose = animatable.transform(i / 40);
      expect(pose.dy.abs(), lessThanOrEqualTo(0.02));
      expect((pose.scaleX - 1).abs(), lessThanOrEqualTo(0.02));
      expect((pose.scaleY - 1).abs(), lessThanOrEqualTo(0.02));
      expect(pose.rotation.abs(), lessThanOrEqualTo(0.05)); // ~3 degrees
    }
  });
}
