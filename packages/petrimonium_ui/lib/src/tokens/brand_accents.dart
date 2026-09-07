import 'package:flutter/material.dart';

/// The handful of brand accents that are deliberately *theme-invariant*:
/// they read as the exact same color in Light and Dark, because they are the
/// product's signature rather than a surface that has to adapt.
///
/// Why this exists as an injected extension rather than a constant: each
/// Petrimonium product owns its own accents (Academy is cyan/violet, Wallet
/// emerald, Health terracotta). A widget living in this package cannot
/// compile-time-bind to any one product's palette without the package
/// depending on an app, which is exactly the direction that must never
/// exist. So the product supplies its accents once, at theme construction,
/// and shared widgets read them back through `context.brand`.
///
/// Keep this set small. It is not a dumping ground for every color a product
/// owns — only the accents that shared widgets genuinely need. A color used
/// by exactly one product's own screens belongs in that product, not here.
@immutable
class PetrimoniumBrandAccents extends ThemeExtension<PetrimoniumBrandAccents> {
  const PetrimoniumBrandAccents({
    required this.gradient,
    required this.accent,
    required this.accentDeep,
    required this.mentorGlow,
    required this.highlight,
  });

  /// The product's strongest visual signature — primary CTAs, progression,
  /// "this is the current step" states. Rendered as a gradient so every one
  /// of those moments reads as the same brand gesture.
  final List<Color> gradient;

  /// Bright primary accent (focus rings, active field borders, link-ish
  /// affordances).
  final Color accent;

  /// Deep counterpart to [accent], for fills that sit behind foreground text.
  final Color accentDeep;

  /// The Mentor's lilac glow. Intentionally the one accent shared across
  /// products: it is how the Mentor reads as the same entity everywhere.
  final Color mentorGlow;

  /// Celebratory/locked-achievement border accent (gold).
  final Color highlight;

  @override
  PetrimoniumBrandAccents copyWith({
    List<Color>? gradient,
    Color? accent,
    Color? accentDeep,
    Color? mentorGlow,
    Color? highlight,
  }) {
    return PetrimoniumBrandAccents(
      gradient: gradient ?? this.gradient,
      accent: accent ?? this.accent,
      accentDeep: accentDeep ?? this.accentDeep,
      mentorGlow: mentorGlow ?? this.mentorGlow,
      highlight: highlight ?? this.highlight,
    );
  }

  @override
  PetrimoniumBrandAccents lerp(
    ThemeExtension<PetrimoniumBrandAccents>? other,
    double t,
  ) {
    if (other is! PetrimoniumBrandAccents) return this;
    // Gradients are lerped stop-by-stop where the two sides have the same
    // number of stops; when they don't, snapping at the midpoint is the only
    // honest answer (there is no meaningful blend between a 2-stop and a
    // 3-stop gradient) and avoids a RangeError mid-animation.
    final lerpedGradient = gradient.length == other.gradient.length
        ? <Color>[
            for (var i = 0; i < gradient.length; i++)
              Color.lerp(gradient[i], other.gradient[i], t)!,
          ]
        : (t < 0.5 ? gradient : other.gradient);
    return PetrimoniumBrandAccents(
      gradient: lerpedGradient,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDeep: Color.lerp(accentDeep, other.accentDeep, t)!,
      mentorGlow: Color.lerp(mentorGlow, other.mentorGlow, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
    );
  }
}
