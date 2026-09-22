import 'package:flutter/material.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// The chapter heading above the first stage of each [AcademyDomain] on the
/// journey.
///
/// The prototype's journey was six stages long; the real curriculum is
/// nineteen, spread over eight themes, so the timeline needs anchors a
/// learner can orient by — without turning back into the grid of domain
/// cards the journey replaced. Tapping it opens the domain's own screen,
/// which is also what keeps that (still useful) "browse one theme" path
/// reachable now that the Academy tab no longer lists domains.
class JourneyChapterLabel extends StatelessWidget {
  const JourneyChapterLabel({super.key, required this.domain, required this.onTap});

  final AcademyDomain domain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  domain.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: tokens.primary.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right_rounded, size: 15, color: tokens.primary.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
