import 'package:flutter/material.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/academy/domain/entities/journey_stage.dart';
import 'package:petrimonium_academy/features/academy/domain/services/academy_progress_calculator.dart';
import 'package:petrimonium_academy/features/academy/presentation/widgets/academy_progress_bar.dart';
import 'package:petrimonium_academy/features/academy/presentation/widgets/journey/journey_entry_row.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/rive/pet_rive_companion.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

const double _kNodeSize = 34;
const double _kGutterWidth = 38;

/// One stop on the Academy timeline: the node + connector on the left, and
/// the stage itself on the right, unfolded to the depth its
/// [JourneyStage.state] deserves.
///
/// Progressive disclosure is the whole point of this widget — a completed
/// stage collapses to a line, a future one to a title and a lesson count,
/// and only the stage the learner is on opens all the way down to the
/// lesson they should do next. Everything it draws comes from the real
/// catalog + progress the [stage] was built from; nothing here invents a
/// count, a duration or a title.
class JourneyStageTile extends StatelessWidget {
  const JourneyStageTile({
    super.key,
    required this.stage,
    required this.isExpanded,
    required this.onToggle,
    required this.onOpenModule,
    required this.onContinue,
    required this.mascotController,
    required this.isLast,
    this.masteryLabel,
    this.currentStageExtras = const [],
  });

  final JourneyStage stage;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(AcademyModule module) onOpenModule;
  final VoidCallback onContinue;
  final MascotController mascotController;

  /// Drops the connector under the last node so the timeline ends instead of
  /// trailing off.
  final bool isLast;

  /// The school's Mastery tier, shown only once the stage is completed —
  /// Mastery is a performance signal and says nothing useful before there is
  /// a finished performance to describe (see `MasteryCalculator`).
  final String? masteryLabel;

  /// Practice/review activities woven into the current stage (the Financial
  /// Lab entry, today's review). Rendered under the CTA so learning and
  /// practising live on the same journey rather than in a separate catalog.
  final List<Widget> currentStageExtras;

  bool get _isCurrent => stage.state == JourneyStageState.current;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _kGutterWidth,
            child: _Gutter(stage: stage, isLast: isLast),
          ),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final tokens = context.colors;

    return Padding(
      padding: EdgeInsets.only(bottom: _isCurrent ? AppSpacing.xxl + 2 : AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          if (_isCurrent) ...[
            const SizedBox(height: AppSpacing.sm + 1),
            AcademyProgressBar(progress: stage.progress, height: 6),
          ],
          if (stage.missingPrerequisites.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _PrerequisiteNote(titles: stage.missingPrerequisites),
          ],
          if (isExpanded && stage.modules.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...stage.modules.expand(_moduleRows),
          ],
          if (_isCurrent && stage.nextLesson != null) ...[
            const SizedBox(height: AppSpacing.md + 2),
            _ContinueButton(onPressed: onContinue),
          ],
          if (_isCurrent)
            for (final extra in currentStageExtras) ...[const SizedBox(height: AppSpacing.md), extra],
          if (isExpanded && stage.modules.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              Translator.translate(AppStrings.academyModuleStatusComingSoon),
              style: AppTextStyles.caption.copyWith(color: tokens.textTertiary, letterSpacing: 1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final tokens = context.colors;
    final isFuture = stage.state == JourneyStageState.upcoming || stage.state == JourneyStageState.comingSoon;
    final tag = _tagLabel;

    return Semantics(
      button: true,
      expanded: isExpanded,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tag != null) ...[
                    Text(
                      tag.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: _isCurrent ? tokens.primary : tokens.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    stage.school.title,
                    style: (_isCurrent ? AppTextStyles.titleLarge : AppTextStyles.title).copyWith(
                      height: 1.25,
                      fontWeight: _isCurrent ? FontWeight.w800 : FontWeight.w700,
                      color: isFuture ? tokens.textSecondary : tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stage.school.description,
                    style: AppTextStyles.label.copyWith(height: 1.45, color: tokens.textTertiary),
                  ),
                  const SizedBox(height: 5),
                  Text(_countLabel, style: AppTextStyles.caption.copyWith(color: tokens.textTertiary)),
                ],
              ),
            ),
            // The Pet is a companion on the journey, never a control: it is
            // excluded from the semantics tree and from hit testing so it can
            // neither take the stage's tap target nor be announced as one
            // (see the Pet guardrails in docs/ECOSYSTEM.md).
            if (_isCurrent)
              ExcludeSemantics(
                child: IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: PetRiveCompanion(controller: mascotController, size: 56, interactive: false),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _moduleRows(JourneyModuleEntry module) {
    final rows = <Widget>[
      JourneyEntryRow(
        mark: _markForModule(module),
        title: module.module.title,
        meta: _moduleMeta(module),
        badge: module.isCurrent ? Translator.translate(AppStrings.academyJourneyBadgeInProgress) : null,
        highlighted: module.isCurrent,
        onTap: module.status == ModuleStatus.locked ? null : () => onOpenModule(module.module),
      ),
    ];

    // Only the module holding the next lesson unfolds to lesson level: the
    // rest of the journey would otherwise be hundreds of rows of content the
    // learner cannot act on yet. Everything else stays one tap away behind
    // its module row.
    if (module.isCurrent) {
      for (final lesson in module.lessons) {
        rows.add(
          JourneyEntryRow(
            mark: _markForLesson(lesson),
            title: lesson.lesson.title,
            meta: lesson.estimatedMinutes == 0
                ? null
                : Translator.translate(
                    AppStrings.academyJourneyLessonMinutes,
                    params: {'minutes': '${lesson.estimatedMinutes}'},
                  ),
            badge: lesson.isNext ? Translator.translate(AppStrings.academyJourneyBadgeInProgress) : null,
            highlighted: lesson.isNext,
            indented: true,
            onTap: lesson.isNext ? onContinue : null,
          ),
        );
      }
    }

    return rows;
  }

  String? get _tagLabel => switch (stage.state) {
    JourneyStageState.current => Translator.translate(AppStrings.academyJourneyYouAreHere),
    JourneyStageState.upNext => Translator.translate(AppStrings.academyJourneyUpNext),
    _ => null,
  };

  String get _countLabel {
    final total = stage.totalLessons;
    return switch (stage.state) {
      JourneyStageState.completed => [
        Translator.translate(
          AppStrings.academyJourneyStageCompleted,
          params: {'completed': '${stage.completedLessons}', 'total': '$total'},
        ),
        ?masteryLabel,
      ].join(' · '),
      JourneyStageState.current => Translator.translate(
        AppStrings.academyJourneyStageProgress,
        params: {'completed': '${stage.completedLessons}', 'total': '$total'},
      ),
      JourneyStageState.upNext => Translator.translate(
        AppStrings.academyJourneyStageNotStarted,
        params: {'total': '$total'},
      ),
      _ => Translator.translate(AppStrings.academyJourneyStageTotalLessons, params: {'total': '$total'}),
    };
  }

  String _moduleMeta(JourneyModuleEntry module) {
    if (module.status == ModuleStatus.locked && module.missingPrerequisites.isNotEmpty) {
      return Translator.translate(
        AppStrings.academyLockedPrerequisiteLabel,
        params: {'name': module.missingPrerequisites.join(', ')},
      );
    }
    if (module.completedLessons == 0) {
      return Translator.translate(
        AppStrings.academyJourneyStageTotalLessons,
        params: {'total': '${module.totalLessons}'},
      );
    }
    return Translator.translate(
      AppStrings.academyJourneyModuleProgress,
      params: {'completed': '${module.completedLessons}', 'total': '${module.totalLessons}'},
    );
  }

  JourneyRowMark _markForModule(JourneyModuleEntry module) => switch (module.status) {
    ModuleStatus.completed => JourneyRowMark.done,
    ModuleStatus.inProgress => JourneyRowMark.current,
    ModuleStatus.locked || ModuleStatus.comingSoon => JourneyRowMark.locked,
    ModuleStatus.available => JourneyRowMark.todo,
  };

  JourneyRowMark _markForLesson(JourneyLessonEntry lesson) => switch (lesson.status) {
    LessonStatus.completed => JourneyRowMark.done,
    LessonStatus.locked => JourneyRowMark.todo,
    LessonStatus.available => lesson.isNext ? JourneyRowMark.current : JourneyRowMark.todo,
  };
}

/// The timeline itself: the stage's node, and the connector running from it
/// down to the next one.
class _Gutter extends StatelessWidget {
  const _Gutter({required this.stage, required this.isLast});

  final JourneyStage stage;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final isDone = stage.state == JourneyStageState.completed;

    return Column(
      children: [
        _Node(stage: stage),
        if (!isLast)
          Expanded(
            child: Container(
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: isDone ? tokens.primary.withValues(alpha: 0.45) : tokens.border,
            ),
          ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.stage});

  final JourneyStage stage;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final isCurrent = stage.state == JourneyStageState.current;
    final isDone = stage.state == JourneyStageState.completed;
    final isLocked = stage.state == JourneyStageState.locked;

    return Container(
      width: _kNodeSize,
      height: _kNodeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isCurrent ? LinearGradient(colors: context.brand.gradient) : null,
        border: isCurrent
            ? null
            : Border.all(color: isDone ? tokens.primary.withValues(alpha: 0.45) : tokens.border, width: 1.5),
        boxShadow: isCurrent
            ? [BoxShadow(color: context.brand.mentorGlow.withValues(alpha: 0.28), blurRadius: 12, spreadRadius: 2)]
            : null,
      ),
      child: switch (stage.state) {
        JourneyStageState.completed => Icon(Icons.check_rounded, size: 16, color: tokens.primary),
        JourneyStageState.locked => Icon(Icons.lock_outline_rounded, size: 14, color: tokens.textTertiary),
        _ => Text(
          stage.position.toString().padLeft(2, '0'),
          style: AppTextStyles.label.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isCurrent
                ? Colors.white
                : (isLocked || stage.state == JourneyStageState.comingSoon
                      ? tokens.textTertiary
                      : tokens.textSecondary),
          ),
        ),
      },
    );
  }
}

/// Why a stage is blocked, named — never a bare padlock (PRD guardrail: an
/// unmet prerequisite always shows the reason and the way out).
class _PrerequisiteNote extends StatelessWidget {
  const _PrerequisiteNote({required this.titles});

  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 13, color: tokens.textTertiary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            Translator.translate(AppStrings.academyLockedPrerequisiteLabel, params: {'name': titles.join(', ')}),
            style: AppTextStyles.caption.copyWith(color: tokens.textTertiary),
          ),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Material(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: tokens.primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  Translator.translate(AppStrings.academyJourneyContinueLesson),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: tokens.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.arrow_forward_rounded, size: 16, color: tokens.primary),
            ],
          ),
        ),
      ),
    );
  }
}
