import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/app_color_tokens.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_text_styles.dart';

/// The shared primary CTA: a flat, solid-fill button with a brief tap-down
/// scale for tactile feedback — no gradient, no glow, no elevation by
/// default.
///
/// Reused across the app instead of one-off `ElevatedButton`s so every
/// primary CTA (login, quick actions, empty-state "invest now") shares the
/// same flat, Health-derived visual language while still resolving to each
/// product's own accent color.
///
/// [gradientColors]/[pulse] opt back into the old "premium game" chrome
/// (gradient fill, ambient glow, optional idle pulse) — reserved for the
/// login/signup CTA and the Google button, the one place across the app
/// where that treatment is still wanted; every other call site leaves both
/// null/false and stays flat.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required String this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.gradientColors,
    this.pulse = false,
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
    this.gradientColors,
    this.pulse = false,
    this.height,
    this.borderRadius = AppRadii.xl,
    this.expand = true,
  }) : label = null,
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
  /// color with no call-site change. Ignored when [gradientColors] is set.
  final Color? color;

  /// Gradient fill — set to opt into the old glow chrome (see class doc).
  /// `null` (the default) keeps the flat [color] fill with no glow.
  final List<Color>? gradientColors;

  /// Idle pulse animating the glow's blur/spread. Only visible when
  /// [gradientColors] is set — reserve for the single most important CTA on
  /// a screen (per-screen restraint — pulsing every button at once reads as
  /// noisy, not premium).
  final bool pulse;

  final bool isLoading;
  final double? height;
  final double borderRadius;
  final bool expand;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> with TickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final Animation<double> _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  // 1.0 at rest -> 0.97 while pressed. `_pressController` runs its default
  // [0, 1] range; the Tween maps that directly to the visual scale, so the
  // button is never briefly scaled to 0 (which would make it un-hit-testable
  // — `Transform.scale(scale: 0)` is a singular, non-invertible matrix).
  late final Animation<double> _pressScale = Tween<double>(
    begin: 1.0,
    end: 0.97,
  ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant GameButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !oldWidget.pulse) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.pulse && oldWidget.pulse) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
    final gradientColors = widget.gradientColors;
    final fillColor = widget.color ?? tokens.primary;
    // Each product's `primary` token is AA-safe against its own background,
    // not necessarily against white text — pick whichever of black/white
    // actually contrasts with the fill in hand rather than assuming white.
    final onFill = (gradientColors == null && fillColor.computeLuminance() > 0.55) ? Colors.black : Colors.white;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _pressController]),
      builder: (context, child) {
        final scale = _pressScale.value;
        final pulseGlow = 14 + (_pulseAnimation.value * 10);
        final pulseSpread = 1 + (_pulseAnimation.value * 2);

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: _enabled ? 1.0 : 0.5,
            child: Container(
              height: widget.height,
              width: widget.expand ? double.infinity : null,
              decoration: BoxDecoration(
                color: gradientColors == null ? fillColor : null,
                gradient: gradientColors == null
                    ? null
                    : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradientColors),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: gradientColors == null
                    ? null
                    : [
                        BoxShadow(
                          color: gradientColors.last.withValues(alpha: 0.55),
                          blurRadius: pulseGlow,
                          spreadRadius: pulseSpread,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.12),
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
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
              child:
                  widget.child ??
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
