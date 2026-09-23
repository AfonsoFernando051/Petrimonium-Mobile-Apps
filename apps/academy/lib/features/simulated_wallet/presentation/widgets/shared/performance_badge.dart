import 'package:petrimonium_academy/core/utils/academy_formatters.dart';
import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// Small pill showing a signed percentage with a trend arrow, colored
/// positive/negative — reused across the KPI header, holdings rows and
/// allocation legends.
class PerformanceBadge extends StatelessWidget {
  const PerformanceBadge({super.key, required this.percent, this.compact = false});

  final double percent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rounded = AcademyFormatters.rounded(percent);
    final isPositive = rounded > 0;
    final color = rounded == 0
        ? context.colors.textSecondary
        : isPositive
        ? context.colors.success
        : context.colors.error;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rounded == 0
                ? Icons.remove
                : isPositive
                ? Icons.arrow_drop_up
                : Icons.arrow_drop_down,
            color: color,
            size: compact ? 14 : 18,
          ),
          Text(
            AcademyFormatters.percent(percent),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: compact ? 11 : 12),
          ),
        ],
      ),
    );
  }
}
