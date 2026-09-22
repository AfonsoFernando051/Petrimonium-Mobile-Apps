import 'package:flutter/material.dart';
import 'package:petrimonium_academy/core/constants/app_colors.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/di/dependency_injection.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/features/academy/domain/services/academy_progress_calculator.dart';
import 'package:petrimonium_academy/features/academy/presentation/controllers/academy_controller.dart';
import 'package:petrimonium_academy/features/onboarding/presentation/onboarding_constants.dart';
import 'package:petrimonium_academy/features/onboarding/presentation/screens/gamification_intro_screen.dart';
import 'package:petrimonium_academy/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:petrimonium_academy/features/onboarding/presentation/screens/financial_goal_screen.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/widgets/brand_pet_mascot.dart';

/// Onboarding's "here's your track" beat — a vertical, locked/unlocked
/// sequence of the Academy's **schools** (matching the Notion mockup's
/// "Sua trilha começa aqui"), not a generic preview grid.
///
/// The school (not the module, not the lesson) is the unit here for the
/// same reason it is the Academy tab's timeline spine: it is the level the
/// curriculum orders end-to-end and gates with prerequisites. Listing
/// modules instead used to unfold the whole catalog into onboarding —
/// `module.order` is per-school, so "the first modules" actually matched
/// the opening modules of *every* school at once. Only the first
/// [kOnboardingTrackPreviewSchools] are drawn; the rest are summed up in
/// one line, so this step stays a taste of the journey.
///
/// Schools and their locked state are read live from the same
/// `AcademyController`/`AcademyProgressCalculator` the real Academy screen
/// uses, so onboarding never drifts from what the user will actually see
/// once they get there — no fabricated lesson counts or "starts now"
/// claims. If the catalog is still loading or unreachable, the track is
/// simply omitted rather than blocking onboarding — this screen's own
/// progress never depends on it.
class AcademyIntroScreen extends StatefulWidget {
  const AcademyIntroScreen({super.key});

  @override
  State<AcademyIntroScreen> createState() => _AcademyIntroScreenState();
}

class _AcademyIntroScreenState extends State<AcademyIntroScreen> {
  late final AcademyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AcademyController(
      repository: DI.academyProgressRepository,
      catalogRepository: DI.academyCatalogRepository,
      remoteDataSource: DI.academyRemoteDataSource,
    );
    _controller.addListener(_onChanged);
    _controller.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _goNext(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GamificationIntroScreen()));
  }

  void _skip(BuildContext context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const FinancialGoalScreen()));
  }

  /// Lessons the learner will actually find inside a school — summed over
  /// its modules with real content, so a curriculum placeholder never
  /// inflates the number.
  int _lessonCountFor(School school) {
    return _controller
        .modulesForSchool(school)
        .where((module) => module.contentAvailable)
        .fold(0, (sum, module) => sum + module.lessonIds.length);
  }

  @override
  Widget build(BuildContext context) {
    final allSchools = [..._controller.schools]..sort((a, b) => a.order.compareTo(b.order));
    final schools = allSchools.take(kOnboardingTrackPreviewSchools).toList();
    final remaining = allSchools.length - schools.length;
    // The first school the learner can actually open is the only one
    // allowed to claim "começa agora"; every other reachable school is just
    // further down the track.
    final startIndex = schools.indexWhere((school) {
      final status = _controller.schoolStatusFor(school);
      return status == SchoolStatus.available || status == SchoolStatus.inProgress;
    });

    return OnboardingScaffold(
      step: 3,
      totalSteps: 8,
      showSkip: true,
      onSkip: () => _skip(context),
      title: Translator.translate(AppStrings.academyIntroTitle),
      subtitle: Translator.translate(AppStrings.academyIntroSubtitle),
      ctaLabel: Translator.translate(AppStrings.onboardingNext),
      onCta: () => _goNext(context),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < schools.length; i++)
            _TrackStep(
              index: i + 1,
              title: schools[i].title,
              lessonCount: _lessonCountFor(schools[i]),
              status: _controller.schoolStatusFor(schools[i]),
              isStart: i == startIndex,
              // The connector keeps going when a "mais N escolas" line follows.
              isLast: i == schools.length - 1 && remaining == 0,
            ),
          if (remaining > 0) _MoreSchoolsLine(count: remaining),
          if (startIndex >= 0) ...[
            const SizedBox(height: 20),
            _MentorIntroCard(title: schools[startIndex].title, lessonCount: _lessonCountFor(schools[startIndex])),
          ],
        ],
      ),
    );
  }
}

String _lessonCountLabel(int count) {
  final unit = Translator.translate(
    count == 1 ? AppStrings.academyIntroLessonSingular : AppStrings.academyIntroLessonPlural,
  );
  return '$count $unit';
}

class _TrackStep extends StatelessWidget {
  const _TrackStep({
    required this.index,
    required this.title,
    required this.lessonCount,
    required this.status,
    required this.isStart,
    required this.isLast,
  });

  final int index;
  final String title;
  final int lessonCount;
  final SchoolStatus status;

  /// Whether this is the school the learner starts on — the only row that
  /// says "começa agora".
  final bool isStart;
  final bool isLast;

  bool get _isReachable => status != SchoolStatus.locked && status != SchoolStatus.comingSoon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final subtitle = isStart
        ? '${_lessonCountLabel(lessonCount)} · ${Translator.translate(AppStrings.academyIntroStartsNow)}'
        : _lessonCountLabel(lessonCount);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isStart ? const LinearGradient(colors: AppColors.brandGradient) : null,
                  color: isStart ? null : tokens.textPrimary.withValues(alpha: 0.08),
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: isStart ? Colors.white : tokens.textTertiary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!isLast) Expanded(child: Container(width: 1.5, color: tokens.textPrimary.withValues(alpha: 0.12))),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _isReachable ? tokens.textPrimary : tokens.textTertiary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: tokens.textTertiary, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MentorIntroCard extends StatelessWidget {
  const _MentorIntroCard({required this.title, required this.lessonCount});

  final String title;
  final int lessonCount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recorte à cabeça: `cover` + `topCenter` mantém o enquadramento do
        // retrato anterior num avatar circular pequeno.
        const ClipOval(
          child: BrandPetMascot(size: 36, fit: BoxFit.cover, alignment: Alignment.topCenter),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: tokens.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.textPrimary.withValues(alpha: 0.1)),
            ),
            child: Text(
              Translator.translate(
                AppStrings.academyIntroMentorIntro,
                params: {'module': title, 'count': _lessonCountLabel(lessonCount)},
              ),
              style: TextStyle(color: tokens.textSecondary, fontSize: 13, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

/// Stands in for every school past the preview, so the track never claims
/// the journey ends at the fourth school.
class _MoreSchoolsLine extends StatelessWidget {
  const _MoreSchoolsLine({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final unit = Translator.translate(
      count == 1 ? AppStrings.academyIntroSchoolSingular : AppStrings.academyIntroSchoolPlural,
    );

    return Padding(
      // 32 (node) + 14 (gap): lines the text up with the step titles above.
      padding: const EdgeInsets.only(left: 46, top: 4),
      child: Row(
        children: [
          Text(
            Translator.translate(AppStrings.academyIntroMoreSchools, params: {'count': '$count', 'unit': unit}),
            style: TextStyle(color: tokens.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
