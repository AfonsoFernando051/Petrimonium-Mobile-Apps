import 'package:flutter/widgets.dart';
import 'package:petrimonium_academy/features/pet/domain/enums/pet_animation_state.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/animation/pet_animation_sequences.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/animation/pet_pose.dart';

/// Drives [child] through the mascot's motion vocabulary
/// (`PetAnimationSequences`) for the current [state], via [Transform] +
/// [Opacity] only — no image sequences, no `CustomPainter`, no dependency
/// on what [child] actually is. This is the "operate on a supplied Pet
/// visual" abstraction: swapping species, swapping the fallback PNG for a
/// future Lottie asset, or reusing this for a completely different mascot
/// all work unchanged, because the engine never inspects [child].
///
/// Two [AnimationController]s, matching the two-controller shape the
/// previous `PetMascotWidget` already used (a breathing loop + a bump
/// reaction) rather than one shared controller per state:
///
///  * `_loop` plays whichever [PetSequenceKind.loop] mood is current
///    ([PetAnimationState.idle], [think], [sleep], [listening], [talking],
///    [sad]) and repeats indefinitely.
///  * `_reaction` plays a [PetSequenceKind.reaction] burst exactly once
///    ([happy], [celebrate], [victory]) and is [PetPose.combine]d *on top
///    of* whatever the loop is doing, rather than replacing it — the
///    mascot keeps breathing while it bounces. A reaction never changes
///    which loop is remembered as current: once it finishes, whatever mood
///    was already playing underneath is simply what's left.
///
/// **Known limitation — no crossfade between loops.** Swapping `_loop`'s
/// animatable when the mood changes (e.g. idle → listening) restarts it at
/// that sequence's own start pose, which can be a visible instantaneous
/// pop rather than a smooth blend if the two moods sit far apart (idle's
/// rest vs. listening's lifted "at attention" pose is the most noticeable
/// case). A proper fix is a short crossfade blender between two
/// simultaneously-evaluated animatables; not built here since every mood
/// change today is already gated behind a deliberate user/app action
/// (opening the interaction sheet, a message appearing) rather than a
/// rapid flicker between moods, so the pop is a minor, known cost rather
/// than a constant annoyance. Documented here as a concrete next step.
class PetAnimationEngine extends StatefulWidget {
  const PetAnimationEngine({
    super.key,
    required this.state,
    required this.size,
    required this.child,
    this.reducedMotion = false,
  });

  final PetAnimationState state;

  /// The mascot's on-screen size — every pose's `dx`/`dy` is a fraction of
  /// this, not a raw pixel offset, so the same sequence reads
  /// proportionally the same at a 28px inline avatar and a 220px hero
  /// portrait. (The previous implementation's `-18`-pixel bump did not
  /// have this property: at a 28px avatar it moved the mascot most of its
  /// own height.)
  final double size;

  final Widget child;

  /// Mirrors `MediaQuery.of(context).disableAnimations`. Read by the
  /// caller (which already has a [BuildContext]) and passed in as a plain
  /// bool rather than read here, so this widget stays context-free and
  /// trivially testable. When `true`, the mascot renders motionless —
  /// [PetPose.rest] — rather than a slowed-down version of any sequence:
  /// "reduced motion" means stopped, not merely gentler.
  final bool reducedMotion;

  @override
  State<PetAnimationEngine> createState() => _PetAnimationEngineState();
}

class _PetAnimationEngineState extends State<PetAnimationEngine> with TickerProviderStateMixin {
  late final AnimationController _loop;
  late final AnimationController _reaction;
  late Animatable<PetPose> _loopAnimatable;
  late Animatable<PetPose> _reactionAnimatable;

  /// Which loop-kind state `_loop` is currently playing — independent of
  /// `widget.state` once a reaction is playing on top, since a reaction
  /// never changes this. Starts at whatever loop-kind mood the widget
  /// mounts in (falling back to [PetAnimationState.idle] if it happens to
  /// mount mid-reaction, which cannot otherwise occur in practice).
  late PetAnimationState _currentLoopState;

  @override
  void initState() {
    super.initState();
    final initial = PetAnimationSequences.sequenceFor(widget.state);
    _currentLoopState = initial.kind == PetSequenceKind.loop ? widget.state : PetAnimationState.idle;
    final loopSequence = PetAnimationSequences.sequenceFor(_currentLoopState);

    _loop = AnimationController(vsync: this, duration: loopSequence.duration);
    _loopAnimatable = loopSequence.animatable;

    _reaction = AnimationController(vsync: this, duration: initial.duration);
    _reactionAnimatable = initial.kind == PetSequenceKind.reaction
        ? initial.animatable
        : PetAnimationSequences.happy.animatable; // arbitrary; _reaction stays at 0 so never evaluated as playing

    if (!widget.reducedMotion) {
      _loop.repeat();
      if (initial.kind == PetSequenceKind.reaction) _reaction.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant PetAnimationEngine oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.reducedMotion != oldWidget.reducedMotion) {
      if (widget.reducedMotion) {
        _loop.stop();
        _reaction.stop();
      } else {
        _loop.repeat();
      }
    }

    if (widget.state == oldWidget.state) return;
    final sequence = PetAnimationSequences.sequenceFor(widget.state);

    switch (sequence.kind) {
      case PetSequenceKind.loop:
        if (widget.state == _currentLoopState) return;
        _currentLoopState = widget.state;
        _loopAnimatable = sequence.animatable;
        _loop.duration = sequence.duration;
        if (!widget.reducedMotion) _loop.repeat();
      case PetSequenceKind.reaction:
        _reactionAnimatable = sequence.animatable;
        _reaction.duration = sequence.duration;
        if (!widget.reducedMotion) _reaction.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reducedMotion) return widget.child;

    return AnimatedBuilder(
      animation: Listenable.merge([_loop, _reaction]),
      builder: (context, child) {
        final loopPose = _loopAnimatable.evaluate(_loop);
        final reactionPose = _reactionAnimatable.evaluate(_reaction);
        final pose = loopPose.combine(reactionPose);
        return Transform.translate(
          offset: Offset(pose.dx * widget.size, pose.dy * widget.size),
          child: Transform.rotate(
            angle: pose.rotation,
            child: Transform.scale(
              scaleX: pose.scaleX,
              scaleY: pose.scaleY,
              child: pose.opacity == 1 ? child : Opacity(opacity: pose.opacity.clamp(0.0, 1.0), child: child),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
