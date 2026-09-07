import 'package:flutter/material.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';

/// Which of the three layers a piece of information belongs to — the
/// central guardrail across both Petrimonium apps: every financial metric
/// or Mentor statement must say, in text (never color alone), whether it's
/// raw data, a deterministic calculation, or the Mentor's interpretation.
enum DataLayer { data, calculation, mentor }

/// A small pill labeling which [DataLayer] the content below it belongs to.
/// Always paired with an explicit text label (never relies on color alone
/// to convey layer) — see [DataLayer]'s doc.
class LayerChip extends StatelessWidget {
  const LayerChip({super.key, required this.layer, required this.label});

  final DataLayer layer;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final color = switch (layer) {
      DataLayer.data => tokens.textTertiary,
      DataLayer.calculation => tokens.primary,
      DataLayer.mentor => tokens.mentor,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
