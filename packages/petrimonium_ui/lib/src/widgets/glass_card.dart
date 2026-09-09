import 'package:flutter/material.dart';
import '../tokens/app_color_tokens.dart';
import '../tokens/brand_accents.dart';
import '../tokens/app_radii.dart';

/// Surface hierarchy for [GlassCard], ordered by visual weight, lightest to
/// strongest: [standard] is the default "just a card"; [elevated] steps up
/// for content that deserves more presence (a hero stat, a sheet); [active]
/// marks "this is the current/selected thing" with a brand-accent tint;
/// [reward] is the golden/gradient-adjacent treatment for completed/
/// celebratory states; [disabled] recedes below [standard] for locked/
/// inactive content. Same structure in both Light and Dark theme — only the
/// token values (and how visible a shadow reads) differ.
enum CardSurface { standard, elevated, active, reward, disabled }

/// The shared flat card surface: a solid fill, a thin neutral border and, at
/// most, a soft elevation shadow — no blur, no glow. Each product's own
/// [AppColorTokens]/[PetrimoniumBrandAccents] decide the exact colors; this
/// widget only decides the structure.
///
/// Default background/border adapt to the active theme via `context.colors`
/// — pass explicit [backgroundColor]/[borderColor] only when a card needs a
/// specific per-feature accent (e.g. the pink companion card border), since
/// those accent hues are already theme-invariant (see [PetrimoniumBrandAccents]).
/// Explicit [backgroundColor]/[borderColor]/[boxShadow] always win over [surface].
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? backgroundColor;
  final double borderRadius;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  /// Where this card sits in the surface hierarchy. See [CardSurface].
  final CardSurface surface;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderColor,
    this.backgroundColor,
    this.borderRadius = AppRadii.xxl,
    this.borderWidth = 1,
    this.boxShadow,
    this.surface = CardSurface.standard,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final look = _resolveLook(tokens, context.brand);

    final effectiveBg = backgroundColor ?? look.background;
    final effectiveBorder = borderColor ?? look.border;
    final effectiveShadow = boxShadow ?? look.shadow;
    final radius = BorderRadius.circular(borderRadius);

    final inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: radius,
        border: Border.all(color: effectiveBorder, width: borderWidth),
        boxShadow: effectiveShadow,
      ),
      child: child,
    );

    if (margin != null) {
      return Container(margin: margin, child: inner);
    }
    return inner;
  }

  _CardLook _resolveLook(AppColorTokens tokens, PetrimoniumBrandAccents brand) {
    switch (surface) {
      case CardSurface.standard:
        // No glow to rely on — an extremely soft elevation shadow instead
        // of a heavy card shadow.
        return _CardLook(
          background: tokens.surface,
          border: tokens.border,
          shadow: [BoxShadow(color: tokens.shadow, blurRadius: 18, offset: const Offset(0, 6))],
        );
      case CardSurface.elevated:
        return _CardLook(
          background: tokens.surfaceElevated,
          border: tokens.borderStrong,
          shadow: [BoxShadow(color: tokens.shadow.withValues(alpha: tokens.shadow.a * 1.6), blurRadius: 28, offset: const Offset(0, 10))],
        );
      case CardSurface.active:
        // "This is the current step" — a brand-purple tint, not just a
        // stronger neutral shadow, so it reads as meaningfully different
        // from `elevated` rather than just "more of the same".
        return _CardLook(
          background: Color.alphaBlend(brand.mentorGlow.withValues(alpha: 0.05), tokens.surfaceElevated),
          border: brand.mentorGlow.withValues(alpha: 0.4),
          shadow: [BoxShadow(color: brand.mentorGlow.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6))],
        );
      case CardSurface.reward:
        // Completed/celebratory — a golden tint instead of purple, echoing
        // the brand gradient's warm end without tinting every card pink.
        return _CardLook(
          background: Color.alphaBlend(brand.highlight.withValues(alpha: 0.06), tokens.surfaceElevated),
          border: brand.highlight.withValues(alpha: 0.45),
          shadow: [BoxShadow(color: brand.highlight.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
        );
      case CardSurface.disabled:
        // Recedes below `standard` — muted surface, no shadow, so locked
        // content reads as "not here yet" without needing extra Opacity.
        return _CardLook(background: tokens.surfaceMuted, border: tokens.border, shadow: null);
    }
  }
}

class _CardLook {
  const _CardLook({required this.background, required this.border, this.shadow});

  final Color background;
  final Color border;
  final List<BoxShadow>? shadow;
}
