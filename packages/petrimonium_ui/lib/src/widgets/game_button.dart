import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/app_color_tokens.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_text_styles.dart';

/// The shared primary CTA: a flat, solid-fill button with a brief tap-down
/// scale for tactile feedback — no gradient, no glow, no elevation.
///
/// Reused across the app instead of one-off `ElevatedButton`s so every
/// primary CTA (login, quick actions, empty-state "invest now") shares the
/// same flat, Health-derived visual language while still resolving to each
/// product's own accent color.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required String this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.isLoading = false,
    this.height = 56,
    this.borderRadius = AppRadii.xl,
    this.expand = true,
    this.iconTrailing = false,
  }) : child = null;

  /// Same flat/press chrome, but with fully custom content — for CTAs that
  /// need more than an icon+label (e.g. a title+subtitle quick action)
  /// without duplicating this widget's animation logic.
  ///
  /// [height] defaults to `null` here (content-sized) rather than the fixed
  /// 56 the label/icon mode uses — custom content's natural height varies
  /// (a single line vs. an icon+title+subtitle block), and a fixed height
  /// would either clip taller content or leave dead space around shorter
  /// content. `Center` gives its child loose constraints, so a too-small
  /// fixed height here would silently overflow rather than shrink content.
  const GameButton.custom({
    super.key,
    required Widget this.child,
    required this.onPressed,
    this.color,
    this.height,
    this.borderRadius = AppRadii.xl,
    this.expand = true,
  })  : label = null,
        icon = null,
        iconTrailing = false,
        isLoading = false;

  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool iconTrailing;

  /// Solid fill. Defaults to the product's own accent (`context.colors.primary`)
  /// when omitted, so a plain `GameButton` renders in each product's own
  /// color with no call-site change.
  final Color? color;

  final bool isLoading;
  final double? height;
  final double borderRadius;
  final bool expand;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  // 1.0 at rest -> 0.97 while pressed. `_pressController` runs its default
  // [0, 1] range; the Tween maps that directly to the visual scale, so the
  // button is never briefly scaled to 0 (which would make it un-hit-testable
  // — `Transform.scale(scale: 0)` is a singular, non-invertible matrix).
  late final Animation<double> _pressScale = Tween<double>(begin: 1.0, end: 0.97).animate(
    CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _handleTapDown(TapDownDetails _) {
    if (!_enabled) return;
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (!_enabled) return;
    _pressController.reverse();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final fillColor = widget.color ?? tokens.primary;
    // Each product's `primary` token is AA-safe against its own background,
    // not necessarily against white text — pick whichever of black/white
    // actually contrasts with the fill in hand rather than assuming white.
    final onFill = fillColor.computeLuminance() > 0.55 ? Colors.black : Colors.white;

    return AnimatedBuilder(
      animation: _pressController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pressScale.value,
          child: Opacity(
            opacity: _enabled ? 1.0 : 0.5,
            child: Container(
              height: widget.height,
              width: widget.expand ? double.infinity : null,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: child,
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          onTap: _enabled
              ? () {
                  HapticFeedback.selectionClick();
                  widget.onPressed?.call();
                }
              : null,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: Padding(
            padding: widget.child != null ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: widget.child ??
                  (widget.isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: onFill),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null && !widget.iconTrailing) ...[
                              Icon(widget.icon, color: onFill, size: 20),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                widget.label!,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.title.copyWith(color: onFill),
                              ),
                            ),
                            if (widget.icon != null && widget.iconTrailing) ...[
                              const SizedBox(width: 8),
                              Icon(widget.icon, color: onFill, size: 20),
                            ],
                          ],
                        )),
            ),
          ),
        ),
      ),
    );
  }
}
