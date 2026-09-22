import 'package:flutter/material.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/academy/domain/entities/knowledge_level.dart';
import 'package:petrimonium_academy/features/academy/domain/services/knowledge_progress_calculator.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// Top of the Academy tab: what this screen is, plus the one status number
/// that the journey below cannot show on its own.
///
/// Deliberately chrome-free and only three lines tall — the stage the
/// learner is on is meant to be the first thing their eye lands on, so the
/// header states the promise and gets out of the way. Game Level lives in
/// `DashboardScreen`'s AppBar; what is repeated here is Knowledge Progress,
/// which is a different number and exists nowhere else on this tab (see
/// `KnowledgeProgressCalculator`).
class AcademyJourneyHeader extends StatelessWidget {
  const AcademyJourneyHeader({super.key, required this.knowledgeLevel, required this.onExploreFullTrack});

  final KnowledgeLevel knowledgeLevel;

  /// Opens the flat, unscoped view of every module — the journey answers
  /// "what now?", this stays available for "show me everything".
  final VoidCallback onExploreFullTrack;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translator.translate(AppStrings.navAcademy),
                    style: AppTextStyles.headline.copyWith(fontWeight: FontWeight.w800, color: tokens.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Translator.translate(AppStrings.academyJourneySubtitle),
                    style: AppTextStyles.label.copyWith(color: tokens.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onExploreFullTrack,
              icon: const Icon(Icons.format_list_bulleted_rounded, size: 18),
              color: tokens.textSecondary,
              tooltip: Translator.translate(AppStrings.academyJourneyExploreTooltip),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(Icons.psychology_alt_outlined, size: 14, color: tokens.textTertiary),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                Translator.translate(
                  AppStrings.academyKnowledgeLevelLabel,
                  params: {'tier': KnowledgeProgressCalculator.labelFor(knowledgeLevel)},
                ),
                style: AppTextStyles.caption.copyWith(color: tokens.textTertiary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
