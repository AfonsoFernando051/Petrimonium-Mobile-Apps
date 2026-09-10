import 'package:flutter/material.dart';

import '../theme/health_theme.dart';

/// The pill-shaped primary CTA used across every screen in the design
/// (login, pet setup, quick setup, add debt/income). Disabled state matches
/// the prototype: flat gray fill, no shadow, 55% opacity.
/// Largura máxima da coluna de conteúdo, em qualquer ecrã da Health.
///
/// Os artboards do canvas são desenhados a 390px com margens de 24, ou seja
/// 342px de conteúdo. Sem este limite a app estica numa janela de desktop —
/// a grelha de espécies do onboarding chegava a cartões de ~480px de largura.
class HealthContent extends StatelessWidget {
  const HealthContent({super.key, required this.child, this.width = frameWidth});

  /// Largura do artboard (conteúdo + as duas margens de 24).
  static const double frameWidth = 390;

  /// Só o conteúdo, para ecrãs que aplicam as margens por fora.
  static const double bodyWidth = 342;

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: child,
      ),
    );
  }
}

class HealthPrimaryButton extends StatefulWidget {
  const HealthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
    this.gradientColors,
    this.pulse = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  /// Opt-in gradient+glow chrome, reserved for the login/signup CTA — every
  /// other screen that uses this button (pet setup, quick setup, add
  /// debt/income) leaves this null and keeps the flat fill.
  final List<Color>? gradientColors;

  /// Idle pulse animating the glow's blur/spread. Only visible alongside
  /// [gradientColors] — reserve for the single most important CTA on a
  /// screen.
  final bool pulse;

  @override
  State<HealthPrimaryButton> createState() => _HealthPrimaryButtonState();
}

class _HealthPrimaryButtonState extends State<HealthPrimaryButton>
    with SingleTickerProviderStateMixin {
  // Created eagerly in initState (not via a `late final` field initializer)
  // so the flat path — which never builds an AnimatedBuilder and so never
  // touches this controller — doesn't defer its first access to dispose(),
  // where `vsync: this` looks up an already-deactivated element and throws.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    if (widget.pulse) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant HealthPrimaryButton oldWidget) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    final accent = Theme.of(context).colorScheme.primary;
    final gradientColors = widget.gradientColors;

    final content = widget.busy
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          );

    if (gradientColors == null) {
      return Opacity(
        opacity: enabled ? 1 : 0.55,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: enabled ? widget.onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              disabledBackgroundColor: HealthColors.textPrimary.withValues(
                alpha: .12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: content,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowBlur = 14 + (_pulseAnimation.value * 10);
        final glowSpread = 1 + (_pulseAnimation.value * 2);
        return Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.last.withValues(alpha: 0.55),
                  blurRadius: glowBlur,
                  spreadRadius: glowSpread,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? widget.onPressed : null,
          child: Center(child: content),
        ),
      ),
    );
  }
}

/// A single-choice pill, used for Login/Cadastro, país, idioma and
/// sim/não style toggles.
class HealthChip extends StatelessWidget {
  const HealthChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.flex = 1,
    this.expanded = true,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int flex;
  final bool expanded;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final chip = Opacity(
      opacity: enabled ? 1 : .55,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 4 : 14,
            vertical: 12,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? accent : HealthColors.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? accent : HealthColors.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : HealthColors.textPrimary,
            ),
          ),
        ),
      ),
    );
    return expanded ? Expanded(flex: flex, child: chip) : chip;
  }
}

/// The rounded white surface every section of the summary sits on. Named
/// "panel", not "card": in this app a card is a credit card (see
/// [HealthCard] in the domain models), and a screen that shows invoices
/// needs both names in scope at once.
class HealthPanel extends StatelessWidget {
  const HealthPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: HealthColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HealthColors.borderSoft),
      ),
      child: child,
    );
  }
}

/// Small uppercase label pill — used for provenance markers such as
/// "DADO", "CÁLCULO DETERMINÍSTICO" and "MENTOR · INTERPRETAÇÃO DE IA"
/// (PRD requirement: data, calculation and AI interpretation must be
/// visually distinguishable, never relying on color alone).
class ProvenanceBadge extends StatelessWidget {
  const ProvenanceBadge({
    super.key,
    required this.label,
    required this.color,
    required this.tint,
  });

  final String label;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: .5,
          color: color,
        ),
      ),
    );
  }
}

/// Progress dots used at the bottom of onboarding screens.
class ProgressDots extends StatelessWidget {
  const ProgressDots({super.key, required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (index) {
        final active = index + 1 == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? accent
                : HealthColors.textPrimary.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
