import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// How far along the thing a [JourneyEntryRow] stands for is.
enum JourneyRowMark { done, current, todo, locked }

/// One line inside an expanded [JourneyStageTile]: a module of the stage, a
/// lesson of the module the learner is on, or a practice/review activity
/// woven into the same list.
///
/// Deliberately one widget for all four: the journey reads as a single
/// sequence of steps, so a lesson and a lab must not look like different
/// species of thing — only their [badge] and [onTap] differ.
class JourneyEntryRow extends StatelessWidget {
  const JourneyEntryRow({
    super.key,
    required this.mark,
    required this.title,
    this.meta,
    this.badge,
    this.highlighted = false,
    this.indented = false,
    this.onTap,
  });

  final JourneyRowMark mark;
  final String title;

  /// Quiet second line — duration, lesson count, or why the row is locked.
  final String? meta;

  /// Uppercase pill on the trailing edge ("em andamento", "prática", …).
  final String? badge;

  /// The single row the learner should act on next. Renders the badge in the
  /// brand gradient and the title at full weight/contrast — at most one row
  /// per stage should set this, or the "what now?" answer stops being
  /// unmistakable.
  final bool highlighted;

  /// Lessons nested under the module row they belong to.
  final bool indented;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final isLocked = mark == JourneyRowMark.locked;
    // At large text scales the trailing pill stops fitting beside a wrapping
    // title on a narrow phone, so it moves under the text instead of being
    // truncated. Clipping it is not an option — the badge is how "em
    // andamento" and "prática" are told apart.
    final stackedBadge = badge != null && MediaQuery.textScalerOf(context).scale(11) > 15;

    final row = Padding(
      padding: EdgeInsets.only(left: indented ? AppSpacing.xl : 0, top: AppSpacing.sm + 1, bottom: AppSpacing.sm + 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(_markIcon, size: 14, color: _markColor(tokens)),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    height: 1.35,
                    fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                    color: highlighted ? tokens.textPrimary : tokens.textSecondary,
                  ),
                ),
                if (meta != null) ...[
                  const SizedBox(height: 2),
                  Text(meta!, style: AppTextStyles.caption.copyWith(color: tokens.textTertiary)),
                ],
                if (stackedBadge) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _Badge(label: badge!, accent: highlighted),
                  ),
                ],
              ],
            ),
          ),
          if (badge != null && !stackedBadge) ...[
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: _Badge(label: badge!, accent: highlighted),
            ),
          ],
        ],
      ),
    );

    if (onTap == null || isLocked) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadii.md), child: row),
    );
  }

  IconData get _markIcon => switch (mark) {
    JourneyRowMark.done => Icons.check_rounded,
    JourneyRowMark.current => Icons.circle,
    JourneyRowMark.todo => Icons.circle_outlined,
    JourneyRowMark.locked => Icons.lock_outline_rounded,
  };

  Color _markColor(AppColorTokens tokens) => switch (mark) {
    JourneyRowMark.done || JourneyRowMark.current => tokens.primary,
    JourneyRowMark.todo || JourneyRowMark.locked => tokens.textTertiary,
  };
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.accent});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent ? null : tokens.surfaceMuted,
        gradient: accent ? LinearGradient(colors: context.brand.gradient) : null,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: accent ? Colors.white : tokens.textTertiary,
        ),
      ),
    );
  }
}
