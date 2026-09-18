import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/constants/app_colors.dart';
import 'package:petrimonium_academy/features/mentor/presentation/controllers/mentor_chat_controller.dart';

/// The pet at the centre of the Mentor tab, in a glow whose colour, ring and
/// motion follow the stage: a slow bob while waiting, a tilt under a spinning
/// dashed ring while thinking, a quick bob inside a pulsing ring while
/// talking — where it also shrinks to leave room for the speech card.
///
/// A static portrait plus Flutter motion, not the Rive companion: the Rive
/// rigs have no thinking/talking poses yet.
class MentorPetStage extends StatefulWidget {
  const MentorPetStage({super.key, required this.petAsset, required this.phase});

  final String petAsset;
  final MentorStagePhase phase;

  @override
  State<MentorPetStage> createState() => _MentorPetStageState();
}

class _MentorPetStageState extends State<MentorPetStage> with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this, duration: _durationFor(widget.phase));

  static const Color _gold = AppColors.goldenBorder;

  static Duration _durationFor(MentorStagePhase phase) => switch (phase) {
    MentorStagePhase.welcome => const Duration(milliseconds: 3200),
    MentorStagePhase.thinking => const Duration(milliseconds: 1800),
    MentorStagePhase.talking => const Duration(milliseconds: 1100),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(MentorPetStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase) {
      _motion.duration = _durationFor(widget.phase);
      _syncMotion();
    }
  }

  void _syncMotion() {
    if (MediaQuery.of(context).disableAnimations) {
      _motion.stop();
      _motion.value = 0;
    } else {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.phase == MentorStagePhase.talking;
    final glowSize = compact ? 118.0 : 168.0;
    final imageSize = compact ? 90.0 : 130.0;

    final glowColors = switch (widget.phase) {
      MentorStagePhase.welcome => [
        AppColors.neonCyan.withValues(alpha: 0.32),
        AppColors.neonCyan.withValues(alpha: 0.08),
      ],
      MentorStagePhase.thinking => [_gold.withValues(alpha: 0.28), AppColors.neonCyan.withValues(alpha: 0.08)],
      MentorStagePhase.talking => [
        AppColors.neonCyan.withValues(alpha: 0.34),
        context.colors.mentor.withValues(alpha: 0.10),
      ],
    };

    return SizedBox(
      width: glowSize,
      height: glowSize,
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, child) {
          // 0 → 1 → 0 over one cycle, eased like CSS `ease-in-out` keyframes.
          final wave = (1 - math.cos(_motion.value * 2 * math.pi)) / 2;
          return Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [...glowColors, glowColors.last.withValues(alpha: 0)],
                    stops: const [0.0, 0.55, 0.75],
                  ),
                ),
                child: SizedBox.expand(),
              ),
              if (widget.phase == MentorStagePhase.thinking)
                Transform.rotate(
                  // The spinning ring runs on its own slower clock than the tilt.
                  angle: _motion.lastElapsedDuration == null
                      ? 0
                      : (_motion.lastElapsedDuration!.inMilliseconds / 5000) * 2 * math.pi,
                  child: CustomPaint(
                    size: Size.square(glowSize * 0.84),
                    painter: _DashedRingPainter(color: _gold.withValues(alpha: 0.4)),
                  ),
                ),
              if (widget.phase == MentorStagePhase.talking)
                Container(
                  width: glowSize * 0.9,
                  height: glowSize * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4 * (1 - 0.6 * wave)), width: 1.5),
                  ),
                ),
              Transform.translate(
                offset: Offset(0, widget.phase == MentorStagePhase.thinking ? -3 * wave : -5 * wave),
                child: Transform.rotate(
                  angle: widget.phase == MentorStagePhase.thinking ? -6 * math.pi / 180 * wave : 0,
                  child: child,
                ),
              ),
            ],
          );
        },
        child: Image.asset(
          widget.petAsset,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(Icons.pets, color: context.colors.textSecondary, size: imageSize * 0.4),
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.color});

  final Color color;

  static const int _dashes = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Offset.zero & size;
    final sweep = 2 * math.pi / _dashes;
    for (var i = 0; i < _dashes; i++) {
      canvas.drawArc(rect.deflate(1), i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter oldDelegate) => oldDelegate.color != color;
}
