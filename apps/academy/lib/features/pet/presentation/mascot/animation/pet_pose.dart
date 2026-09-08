import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// A single instant of the mascot's motion: the transform + opacity a
/// [PetMascotWidget] frame applies on top of its base visual (the portrait
/// image / evolution art / accessories stack). This is the only shape any
/// pose primitive or composed sequence produces, so a reaction (e.g.
/// [happy]'s bounce) and a loop (e.g. [idle]'s breathing) can be computed
/// independently and simply added together — see [combine].
///
/// [dx]/[dy] are fractions of the mascot's own `size`, not raw pixels, so
/// the same sequence reads proportionally the same whether it drives a
/// 28px inline avatar or a 220px hero portrait. [rotation] is radians
/// (Flutter's [Transform.rotate] convention) — pose builders in
/// `pet_animation_sequences.dart` accept degrees and convert once, so an
/// amplitude typo can't silently turn into several full turns.
@immutable
class PetPose {
  const PetPose({
    this.dx = 0,
    this.dy = 0,
    this.rotation = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.opacity = 1,
  });

  /// The neutral pose: no offset, no rotation, unit scale, fully opaque.
  static const PetPose rest = PetPose();

  /// Fractions of `size` (not pixels) — see class doc.
  final double dx;
  final double dy;

  /// Radians.
  final double rotation;

  final double scaleX;
  final double scaleY;
  final double opacity;

  /// Layers [other] on top of this pose: offsets and rotation add, scales
  /// multiply, opacity multiplies. This is how a one-shot reaction (a tap
  /// bounce, a celebration jump) rides on top of whatever loop (breathing,
  /// a slow thinking tilt) is already playing, instead of replacing it —
  /// the loop never has to pause for a reaction to play.
  PetPose combine(PetPose other) {
    if (identical(other, PetPose.rest)) return this;
    if (identical(this, PetPose.rest)) return other;
    return PetPose(
      dx: dx + other.dx,
      dy: dy + other.dy,
      rotation: rotation + other.rotation,
      scaleX: scaleX * other.scaleX,
      scaleY: scaleY * other.scaleY,
      opacity: opacity * other.opacity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PetPose &&
          dx == other.dx &&
          dy == other.dy &&
          rotation == other.rotation &&
          scaleX == other.scaleX &&
          scaleY == other.scaleY &&
          opacity == other.opacity);

  @override
  int get hashCode => Object.hash(dx, dy, rotation, scaleX, scaleY, opacity);

  @override
  String toString() =>
      'PetPose(dx: $dx, dy: $dy, rotation: $rotation, scaleX: $scaleX, scaleY: $scaleY, opacity: $opacity)';
}

/// Linear interpolation between two [PetPose]s, field by field. Used as the
/// leaf tween inside every [TweenSequenceItem] a pose primitive builds —
/// easing/timing comes from the [CurveTween] each item is chained with, not
/// from this.
class PetPoseTween extends Tween<PetPose> {
  PetPoseTween({required PetPose super.begin, required PetPose super.end});

  @override
  PetPose lerp(double t) => PetPose(
    dx: ui.lerpDouble(begin!.dx, end!.dx, t)!,
    dy: ui.lerpDouble(begin!.dy, end!.dy, t)!,
    rotation: ui.lerpDouble(begin!.rotation, end!.rotation, t)!,
    scaleX: ui.lerpDouble(begin!.scaleX, end!.scaleX, t)!,
    scaleY: ui.lerpDouble(begin!.scaleY, end!.scaleY, t)!,
    opacity: ui.lerpDouble(begin!.opacity, end!.opacity, t)!,
  );
}
