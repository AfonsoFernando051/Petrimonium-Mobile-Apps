import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/academy/domain/entities/journey_stage.dart';
import 'package:petrimonium_academy/features/home/domain/entities/journey_summary.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// Home's answer to "where am I on the journey" — one stage, one progress,
/// one way through to the rest.
///
/// It replaced a full list of every school on Home: that list made Home a
/// catalog of everything the learner could study, when the question Home
/// exists to answer is what to do next. The whole curriculum still lives on
/// the Academia tab, one tap away through this card's CTA — see
/// [JourneySummary] for the slice this draws.
class JourneySummaryCard extends StatelessWidget {
  const JourneySummaryCard({super.key, required this.summary, required this.onOpenJourney});

  final JourneySummary summary;

  /// Opens the Academia tab, where the full timeline lives.
  final VoidCallback onOpenJourney;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          Translator.translate(AppStrings.homeJourneySummaryLabel),
          style: AppTextStyles.caption.copyWith(
            color: tokens.primary.withValues(alpha: 0.6),
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        GlassCard(
          borderColor: tokens.primary.withValues(alpha: 0.18),
          borderRadius: AppRadii.lg,
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onOpenJourney();
              },
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StageRail(summary: summary),
                    const SizedBox(height: AppSpacing.md + 2),
                    Text(_title(), style: AppTextStyles.title.copyWith(color: tokens.textPrimary, height: 1.25)),
                    const SizedBox(height: 4),
                    Text(_meta(), style: AppTextStyles.caption.copyWith(color: tokens.textTertiary)),
                    if (summary.nextStage != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        Translator.translate(
                          AppStrings.homeJourneyNextStage,
                          params: {'title': summary.nextStage!.school.title},
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(color: tokens.textTertiary),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Text(
                          Translator.translate(AppStrings.homeViewFullJourneyCta),
                          style: AppTextStyles.label.copyWith(color: tokens.primary, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: tokens.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _title() =>
      summary.isComplete ? Translator.translate(AppStrings.homeJourneyCompleteTitle) : summary.focus.school.title;

  String _meta() {
    if (summary.isComplete) {
      return Translator.translate(
        AppStrings.homeJourneyCompleteStages,
        params: {'completed': '${summary.completedStages}', 'total': '${summary.totalStages}'},
      );
    }
    final position = Translator.translate(
      AppStrings.homeJourneyStagePosition,
      params: {'position': '${summary.focus.position}', 'total': '${summary.totalStages}'},
    );
    final lessons = Translator.translate(
      AppStrings.academyJourneyStageProgress,
      params: {'completed': '${summary.focus.completedLessons}', 'total': '${summary.focus.totalLessons}'},
    );
    return '$position · $lessons';
  }
}

/// The journey drawn as a handful of nodes: done, here, ahead. Never the
/// whole curriculum — the faded stubs at either end are how it says there
/// is more on both sides without naming any of it.
class _StageRail extends StatelessWidget {
  const _StageRail({required this.summary});

  final JourneySummary summary;

  @override
  Widget build(BuildContext context) {
    final stages = summary.window;

    return SizedBox(
      height: 16,
      child: Row(
        children: [
          if (summary.hasMoreBefore) _Connector(done: stages.first.state == JourneyStageState.completed, width: 10),
          for (var i = 0; i < stages.length; i++) ...[
            if (i > 0) Expanded(child: _Connector(done: stages[i - 1].state == JourneyStageState.completed)),
            _StageDot(stage: stages[i]),
          ],
          if (summary.hasMoreAfter) _Connector(done: stages.last.state == JourneyStageState.completed, width: 10),
        ],
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.done, this.width});

  final bool done;

  /// Set only for the truncation stubs at either end; the connectors
  /// between two drawn stages stretch instead.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final color = done ? tokens.primary.withValues(alpha: 0.45) : tokens.border;

    return Container(
      width: width,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        gradient: width == null
            ? null
            // The stubs fade out toward the edge of the card, so the rail
            // reads as continuing rather than stopping.
            : LinearGradient(colors: [color.withValues(alpha: 0), color]),
        color: width == null ? color : null,
      ),
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({required this.stage});

  final JourneyStage stage;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final isCurrent = stage.state == JourneyStageState.current;
    final isDone = stage.state == JourneyStageState.completed;

    if (isCurrent) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: context.brand.gradient),
          boxShadow: [
            BoxShadow(color: context.brand.mentorGlow.withValues(alpha: 0.32), blurRadius: 10, spreadRadius: 1),
          ],
        ),
      );
    }

    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? tokens.primary.withValues(alpha: 0.65) : Colors.transparent,
        border: isDone ? null : Border.all(color: tokens.border, width: 1.5),
      ),
    );
  }
}
