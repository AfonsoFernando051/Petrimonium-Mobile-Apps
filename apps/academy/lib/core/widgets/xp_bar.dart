import 'package:flutter/material.dart';
import 'package:petrimonium_academy/core/constants/app_colors.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// A thin, animated, glowing progress bar for XP/level progress — a
/// rounded gradient-glow fill over a track, shared so every screen that
/// shows progress (Home's companion card, onboarding's Gamification demo)
/// draws it the same way instead of re-hand-rolling it. [progress] animates smoothly on change; honors
/// reduced-motion by jumping straight to the target value.
class XpBar extends StatelessWidget {
  const XpBar({super.key, required this.progress, this.label, this.color = AppColors.neonCyan, this.height = 8});

  /// 0.0-1.0 fill fraction.
  final double progress;
  final String? label;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final clamped = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Stack(
            children: [
              Container(height: height, width: double.infinity, color: tokens.textTertiary.withValues(alpha: 0.18)),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clamped,
                child: AnimatedContainer(
                  duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withValues(alpha: 0.75), color]),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: height)],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(label!, style: AppTextStyles.label.copyWith(color: tokens.textSecondary)),
        ],
      ],
    );
  }
}
