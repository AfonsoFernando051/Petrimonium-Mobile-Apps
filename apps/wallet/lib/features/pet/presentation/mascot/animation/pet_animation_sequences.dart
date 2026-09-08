import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:petrimonium_wallet/features/pet/domain/enums/pet_animation_state.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/animation/pet_pose.dart';

/// One composed motion: what to animate through ([animatable], a
/// [PetPose]-valued curve over `t` in `[0, 1]`) and how long one pass takes.
/// [kind] decides how [PetAnimationEngine] plays it — see its doc comment.
class PetMotionSequence {
  const PetMotionSequence({
    required this.animatable,
    required this.duration,
    required this.kind,
  });

  final Animatable<PetPose> animatable;
  final Duration duration;
  final PetSequenceKind kind;
}

/// [loop] sequences (idle, think, sleep, listening, talking, sad) are
/// persistent moods: they begin where they end so `AnimationController
/// .repeat()` never pops, and they play for as long as [PetAnimationState]
/// says that mood is current.
///
/// [reaction] sequences (happy, celebrate, victory) are momentary: they
/// always both begin *and* end at [PetPose.rest] and play exactly once, so
/// [PetPose.combine]-ing them on top of whichever loop is already running
/// adds a punch without interrupting the mascot's breathing — the loop
/// never has to stop for a reaction to play, and the reaction cleanly
/// contributes nothing once it settles.
enum PetSequenceKind { loop, reaction }

/// Rive's rotation-in-radians convention bit this exact codebase once
/// already this week: a hand-converted "14 degrees" literal was actually 14
/// radians, and every part span most of a turn. Every rotation amplitude
/// here is authored in degrees and funnelled through this single
/// conversion — never a hand-computed radian literal — so that mistake
/// can't repeat itself.
double _deg(double degrees) => degrees * (math.pi / 180);

/// One leg of a [TweenSequence]: animate into [pose] over [weight] (a
/// fraction of the total duration, same convention as
/// [TweenSequenceItem.weight]) along [curve].
typedef _Waypoint = (PetPose pose, double weight, Curve curve);

Animatable<PetPose> _sequence(List<_Waypoint> waypoints, {PetPose start = PetPose.rest}) {
  var previous = start;
  final items = <TweenSequenceItem<PetPose>>[];
  for (final (pose, weight, curve) in waypoints) {
    items.add(
      TweenSequenceItem<PetPose>(
        tween: PetPoseTween(begin: previous, end: pose).chain(CurveTween(curve: curve)),
        weight: weight,
      ),
    );
    previous = pose;
  }
  return TweenSequence<PetPose>(items);
}

/// The mascot's full motion vocabulary, one [PetMotionSequence] per
/// [PetAnimationState]. Every amplitude here is deliberately small —
/// see the module doc in `pet_animation_engine.dart` for why: this is a
/// companion meant to be glanced at for minutes at a time, not a cartoon
/// performing for attention.
///
/// Kept as a set of pure functions/values with no widget or controller
/// dependency, so each sequence's shape (waypoints, weights, curves) can be
/// asserted on directly in tests without pumping a widget tree.
abstract final class PetAnimationSequences {
  static PetMotionSequence sequenceFor(PetAnimationState state) => switch (state) {
    PetAnimationState.idle => idle,
    PetAnimationState.think => think,
    PetAnimationState.sleep => sleep,
    PetAnimationState.listening => listening,
    PetAnimationState.talking => talking,
    PetAnimationState.sad => sad,
    PetAnimationState.happy => happy,
    PetAnimationState.celebrate => celebrate,
    PetAnimationState.victory => victory,
  };

  // ---- Persistent moods (loop) -------------------------------------------

  /// The default state. A single ~6.4s cycle: a slow breathing rise/fall
  /// with one small, almost-incidental tilt near the two-thirds mark — the
  /// closest a fixed, testable animation gets to "occasionally glances
  /// around" without a randomized Timer scheduler (see the engine's doc
  /// comment on why that trade-off was made). Begins and ends at
  /// [PetPose.rest] so the repeat is seamless.
  static final PetMotionSequence idle = PetMotionSequence(
    kind: PetSequenceKind.loop,
    duration: const Duration(milliseconds: 6400),
    animatable: _sequence([
      (const PetPose(dy: -0.012, scaleX: 1.006, scaleY: 1.014), 35, Curves.easeInOutSine),
      (PetPose.rest, 25, Curves.easeInOutSine),
      (PetPose(dy: -0.004, scaleY: 0.995, rotation: _deg(1.4)), 15, Curves.easeInOutSine),
      (PetPose.rest, 25, Curves.easeInOutSine),
    ]),
  );

  /// A slow side-to-side tilt, as if weighing something — used while the
  /// app is generating a response or analysing data. Loops indefinitely
  /// until the caller has an answer.
  static final PetMotionSequence think = PetMotionSequence(
    kind: PetSequenceKind.loop,
    duration: const Duration(milliseconds: 2600),
    animatable: _sequence(
      [
        (PetPose(dy: -0.006, rotation: _deg(3), scaleX: 0.997, scaleY: 1.004), 50, Curves.easeInOutSine),
        (PetPose(dy: -0.006, rotation: _deg(-3), scaleX: 1.004, scaleY: 0.997), 50, Curves.easeInOutSine),
      ],
      start: PetPose(dy: -0.006, rotation: _deg(-3), scaleX: 1.004, scaleY: 0.997),
    ),
  );

  /// Lowered and slow. Deliberately does not attempt to fake closed eyes on
  /// a static asset (see the engine's limitations doc) — rests its case on
  /// position and a slowed breath instead.
  static final PetMotionSequence sleep = PetMotionSequence(
    kind: PetSequenceKind.loop,
    duration: const Duration(milliseconds: 4800),
    animatable: _sequence(
      [
        (const PetPose(dy: 0.020, scaleX: 1.010, scaleY: 0.992), 50, Curves.easeInOutSine),
        (const PetPose(dy: 0.028, scaleX: 0.995, scaleY: 0.978), 50, Curves.easeInOutSine),
      ],
      start: const PetPose(dy: 0.028, scaleX: 0.995, scaleY: 0.978),
    ),
  );

  /// A small, held "at attention" pose with a tiny breathing oscillation —
  /// entered when the user opens the interaction sheet. See
  /// [PetAnimationEngine]'s note on the one-frame pop when swapping between
  /// loop sequences; this is the state most likely to show it, since it
  /// starts noticeably lifted relative to [idle].
  static final PetMotionSequence listening = PetMotionSequence(
    kind: PetSequenceKind.loop,
    duration: const Duration(milliseconds: 2200),
    animatable: _sequence(
      [
        (PetPose(dy: -0.030, scaleX: 1.028, scaleY: 1.032, rotation: _deg(-0.6)), 50, Curves.easeInOutSine),
        (PetPose(dy: -0.026, scaleX: 1.024, scaleY: 1.028, rotation: _deg(0.6)), 50, Curves.easeInOutSine),
      ],
      start: PetPose(dy: -0.026, scaleX: 1.024, scaleY: 1.028, rotation: _deg(0.6)),
    ),
  );

  /// A quick, tight pulse simulating conversational energy while a speech
  /// bubble is on screen — noticeably snappier than [idle]'s breathing so
  /// it reads as "speaking" rather than "resting," with no lip-sync implied.
  static final PetMotionSequence talking = PetMotionSequence(
    kind: PetSequenceKind.loop,
    duration: const Duration(milliseconds: 850),
    animatable: _sequence(
      [
        (PetPose(dy: -0.006, scaleX: 1.006, scaleY: 1.008, rotation: _deg(-0.8)), 50, Curves.easeInOutSine),
        (PetPose(dy: -0.012, scaleX: 1.012, scaleY: 1.014, rotation: _deg(0.8)), 50, Curves.easeInOutSine),
      ],
      start: PetPose(dy: -0.012, scaleX: 1.012, scaleY: 1.014, rotation: _deg(0.8)),
    ),
  );

  /// Concern, not distress: lowered, a slight constant downward tilt, and a
  /// slow breath — never a sudden drop, so it can't read as scolding or
  /// punishing the user (see `PetAnimationState.sad`'s doc comment).
  static final PetMotionSequence sad = PetMotionSequence(
    kind: PetSequenceKind.loop,
    duration: const Duration(milliseconds: 5200),
    animatable: _sequence(
      [
        (PetPose(dy: 0.018, scaleX: 0.995, scaleY: 0.990, rotation: _deg(-1.2)), 50, Curves.easeInOutSine),
        (PetPose(dy: 0.022, scaleX: 0.990, scaleY: 0.985, rotation: _deg(-1.2)), 50, Curves.easeInOutSine),
      ],
      start: PetPose(dy: 0.022, scaleX: 0.990, scaleY: 0.985, rotation: _deg(-1.2)),
    ),
  );

  // ---- Momentary reactions (reaction) -------------------------------------

  /// A quick, light bounce — the tap/pet reaction, and the smallest of the
  /// three reactions. anticipation → pop → settle → rest, ~650ms.
  static final PetMotionSequence happy = PetMotionSequence(
    kind: PetSequenceKind.reaction,
    duration: const Duration(milliseconds: 650),
    animatable: _sequence([
      (const PetPose(dy: 0.010, scaleX: 1.02, scaleY: 0.97), 12, Curves.easeIn),
      (PetPose(dy: -0.11, scaleX: 0.96, scaleY: 1.05, rotation: _deg(3)), 28, Curves.easeOutCubic),
      (PetPose(dy: 0.015, scaleX: 1.01, scaleY: 0.985, rotation: _deg(-1)), 30, Curves.easeOutBack),
      (PetPose.rest, 30, Curves.easeOutCubic),
    ]),
  );

  /// anticipation crouch → jump+stretch → land+squash → rebound → rest,
  /// ~1.15s. A real achievement, kept polished rather than exaggerated.
  static final PetMotionSequence celebrate = PetMotionSequence(
    kind: PetSequenceKind.reaction,
    duration: const Duration(milliseconds: 1150),
    animatable: _sequence([
      (const PetPose(dy: 0.018, scaleX: 1.06, scaleY: 0.94), 12, Curves.easeIn),
      (PetPose(dy: -0.16, scaleX: 0.94, scaleY: 1.08, rotation: _deg(-6)), 26, Curves.easeOutCubic),
      (PetPose(dy: 0.012, scaleX: 1.07, scaleY: 0.93, rotation: _deg(2)), 22, Curves.easeIn),
      (PetPose(dy: -0.03, scaleX: 0.99, scaleY: 1.02, rotation: _deg(-1)), 20, Curves.easeOutBack),
      (PetPose.rest, 20, Curves.easeOutCubic),
    ]),
  );

  /// The same shape as [celebrate], scaled up with one extra rebound for a
  /// major milestone — anticipation → jump+stretch → land+squash → rebound
  /// → smaller rebound → rest, ~1.55s. Reserved for events big enough to
  /// warrant it; see `MascotController.evaluateEvolution`.
  static final PetMotionSequence victory = PetMotionSequence(
    kind: PetSequenceKind.reaction,
    duration: const Duration(milliseconds: 1550),
    animatable: _sequence([
      (const PetPose(dy: 0.020, scaleX: 1.08, scaleY: 0.92), 10, Curves.easeIn),
      (PetPose(dy: -0.22, scaleX: 0.92, scaleY: 1.10, rotation: _deg(8)), 22, Curves.easeOutCubic),
      (PetPose(dy: 0.016, scaleX: 1.10, scaleY: 0.90, rotation: _deg(-3)), 16, Curves.easeIn),
      (PetPose(dy: -0.05, scaleX: 0.985, scaleY: 1.035, rotation: _deg(2)), 18, Curves.easeOutBack),
      (PetPose(dy: -0.012, scaleX: 0.995, scaleY: 1.01, rotation: _deg(-0.6)), 16, Curves.easeOutBack),
      (PetPose.rest, 18, Curves.easeOutCubic),
    ]),
  );
}
