import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petrimonium_academy/core/di/dependency_injection.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/features/academy/domain/entities/journey_stage.dart';
import 'package:petrimonium_academy/features/academy/presentation/controllers/academy_controller.dart';
import 'package:petrimonium_academy/features/academy/presentation/screens/academy_domain_detail_screen.dart';
import 'package:petrimonium_academy/features/academy/presentation/screens/all_modules_screen.dart';
import 'package:petrimonium_academy/features/academy/presentation/screens/financial_lab/financial_lab_home_screen.dart';
import 'package:petrimonium_academy/features/academy/presentation/screens/lesson_screen.dart';
import 'package:petrimonium_academy/features/academy/presentation/screens/module_detail_screen.dart';
import 'package:petrimonium_academy/features/academy/presentation/widgets/academy_catalog_error_state.dart';
import 'package:petrimonium_academy/features/academy/presentation/widgets/academy_review_card.dart';
import 'package:petrimonium_academy/features/academy/presentation/widgets/financial_lab_entry_card.dart';
import 'package:petrimonium_academy/features/academy/presentation/widgets/journey/academy_journey_header.dart';
import 'package:petrimonium_academy/features/academy/presentation/widgets/journey/journey_chapter_label.dart';
import 'package:petrimonium_academy/features/academy/presentation/widgets/journey/journey_stage_tile.dart';
import 'package:petrimonium_academy/features/academy/presentation/widgets/mastery_tier_presentation.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/pet_companion_controller.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';

/// The "Academia" tab: the learning journey as one timeline — where the
/// learner has been, where they are, and what comes after — instead of a
/// catalog of everything the curriculum contains.
///
/// The timeline's unit is a [School] (see `AcademyJourneyBuilder`): the level
/// the curriculum already orders end to end and gates with prerequisites.
/// Only the stage holding the next lesson unfolds to lesson level; finished
/// stages collapse to a line and future ones to a title and a lesson count,
/// so "what should I learn next?" is answerable without scrolling (see
/// `docs/ACADEMY_ENGINE.md` §5). Practice and review are rendered inside
/// that stage rather than as separate cards — the journey is where the
/// learner acts, so the actions live on it.
///
/// No own `Scaffold`/`AppBar`/background — like `SimulatedWalletScreen` and
/// `MentorScreen`, this is embedded directly in `DashboardScreen`'s shared
/// `Scaffold`/`AppBar`/`CosmicBackground`/`IndexedStack`. Module detail and
/// individual lessons remain separately pushed screens (they need their own
/// back navigation); only the top-level tab content lives here.
class AcademyHomeScreen extends StatefulWidget {
  const AcademyHomeScreen({
    super.key,
    required this.mascotController,
    required this.companionController,
    required this.onOpenPortfolioTab,
  });

  final MascotController mascotController;

  /// Offers the "continue where you left off" companion nudge once the
  /// next lesson is known — see `AcademyPetBehavior._academyNudge`.
  final PetCompanionController companionController;

  /// In-app fallback for the §1.6 Wallet bridge CTA on Financial Lab
  /// completion — see `WalletBridgeCta`.
  final VoidCallback onOpenPortfolioTab;

  @override
  State<AcademyHomeScreen> createState() => _AcademyHomeScreenState();
}

class _AcademyHomeScreenState extends State<AcademyHomeScreen> {
  late final AcademyController _controller;
  bool _companionNotified = false;

  /// Which stage is unfolded. `null` until the first load resolves the
  /// journey, after which the stage the learner is on opens itself — the
  /// screen should never require a tap to answer "what now?". Once the user
  /// taps any stage header, their choice wins for the rest of the session.
  String? _expandedStageId;
  bool _expandedStageChosenByUser = false;

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
    _notifyCompanionOnce();
  }

  // Only offered once per screen lifetime — `PetCompanionController`'s own
  // cooldown/priority rules decide whether it's actually shown; this just
  // avoids re-evaluating on every rebuild the ChangeNotifier triggers.
  void _notifyCompanionOnce() {
    if (_companionNotified || _controller.isLoading || _controller.isCatalogLoading) {
      return;
    }
    final reviewCount = _controller.reviewQueue.length;
    final nextLesson = _controller.nextLesson;
    if (reviewCount == 0 && nextLesson == null) return;
    _companionNotified = true;
    widget.companionController.enterContext(
      PetContext.academy,
      data: {
        if (nextLesson != null) 'lessonTitle': nextLesson.title,
        if (reviewCount > 0) 'reviewDueCount': '$reviewCount',
      },
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openLesson(Lesson lesson) async {
    unawaited(HapticFeedback.selectionClick());
    await Navigator.of(context).push(
      fadeRoute(
        LessonScreen(lesson: lesson, catalog: _controller.snapshot!, mascotController: widget.mascotController),
      ),
    );
    unawaited(_controller.load());
  }

  Future<void> _openModule(AcademyModule module) async {
    unawaited(HapticFeedback.selectionClick());
    await Navigator.of(
      context,
    ).push(fadeRoute(ModuleDetailScreen(module: module, mascotController: widget.mascotController)));
    unawaited(_controller.load());
  }

  Future<void> _openDomain(AcademyDomain domain) async {
    unawaited(HapticFeedback.selectionClick());
    await Navigator.of(
      context,
    ).push(fadeRoute(AcademyDomainDetailScreen(domain: domain, mascotController: widget.mascotController)));
    unawaited(_controller.load());
  }

  Future<void> _openFullTrack() async {
    unawaited(HapticFeedback.selectionClick());
    await Navigator.of(context).push(fadeRoute(AllModulesScreen(mascotController: widget.mascotController)));
    unawaited(_controller.load());
  }

  /// [effectiveExpandedId] is what is actually open on screen right now,
  /// which is not the same as [_expandedStageId] before the user has chosen
  /// anything: until then the current stage is open while the field is still
  /// `null`, and toggling against the field alone would re-open the stage
  /// the user just tried to close.
  void _toggleStage(JourneyStage stage, String? effectiveExpandedId) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _expandedStageChosenByUser = true;
      _expandedStageId = effectiveExpandedId == stage.school.id ? null : stage.school.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds when the user switches language in Settings — this screen's
    // chrome keys off `Translator.currentLanguage` directly, while the
    // curriculum content itself is re-fetched by `_controller`'s own
    // language listener (see `AcademyController._onLanguageChanged`).
    return ValueListenableBuilder<String>(
      valueListenable: Translator.languageNotifier,
      builder: (context, _, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final tokens = context.colors;

    if (_controller.isLoading || _controller.isCatalogLoading) {
      return const AppLoadingIndicator();
    }

    if (_controller.snapshot == null) {
      return AcademyCatalogErrorState(onRetry: _controller.load);
    }

    final journey = _controller.journey;
    final expandedStageId = _resolveExpandedStageId(journey);

    return RefreshIndicator(
      color: tokens.primary,
      backgroundColor: tokens.surfaceElevated,
      onRefresh: _controller.load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AcademyJourneyHeader(knowledgeLevel: _controller.knowledgeLevel, onExploreFullTrack: _openFullTrack),
            const SizedBox(height: AppSpacing.xxl),
            for (var i = 0; i < journey.length; i++) ...[
              if (_startsNewChapter(journey, i))
                JourneyChapterLabel(domain: journey[i].domain!, onTap: () => _openDomain(journey[i].domain!)),
              JourneyStageTile(
                stage: journey[i],
                isExpanded: expandedStageId == journey[i].school.id,
                isLast: i == journey.length - 1,
                masteryLabel: _masteryLabelFor(journey[i]),
                mascotController: widget.mascotController,
                onToggle: () => _toggleStage(journey[i], expandedStageId),
                onOpenModule: _openModule,
                onContinue: _continueFrom(journey[i]),
                currentStageExtras: _currentStageExtras(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The user's choice, or — until they make one — the stage they are on.
  String? _resolveExpandedStageId(List<JourneyStage> journey) {
    if (_expandedStageChosenByUser) return _expandedStageId;
    for (final stage in journey) {
      if (stage.state == JourneyStageState.current) return stage.school.id;
    }
    return null;
  }

  bool _startsNewChapter(List<JourneyStage> journey, int index) {
    final domain = journey[index].domain;
    if (domain == null) return false;
    return index == 0 || journey[index - 1].domain?.id != domain.id;
  }

  /// Mastery is only quoted once a school is finished — a performance tier
  /// derived from a handful of answered lessons would read as a verdict on
  /// work the learner has not done yet (see `MasteryCalculator`).
  String? _masteryLabelFor(JourneyStage stage) {
    if (stage.state != JourneyStageState.completed) return null;
    final tier = _controller.masteryTierFor(stage.school);
    return Translator.translate(MasteryTierPresentation.labelKey(tier));
  }

  VoidCallback _continueFrom(JourneyStage stage) {
    final lesson = stage.nextLesson;
    if (lesson == null) return () {};
    return () => _openLesson(lesson);
  }

  /// Review and practice, rendered inside the current stage: both are
  /// activities on the journey, not a parallel catalog. Review only appears
  /// when there is something actually due — an "all caught up" row is not
  /// worth a line (same rule `AcademyReviewCard` already documented).
  List<Widget> _currentStageExtras() {
    return [
      if (_controller.reviewQueue.isNotEmpty)
        AcademyReviewCard(
          lessonCount: _controller.reviewQueue.length,
          estimatedMinutes: _controller.reviewEstimatedMinutes,
          onStart: () => _openLesson(_controller.reviewQueue.first),
        ),
      // The curriculum carries no link between a school and a Financial Lab
      // simulator, so the lab is offered as the journey's practice step
      // rather than pinned to the stage that teaches it. Wiring a specific
      // simulator to a specific school needs that relation to exist in the
      // catalog first — see `LabSimulatorCatalog`.
      FinancialLabEntryCard(
        onTap: () => Navigator.of(context).push(
          fadeRoute(
            FinancialLabHomeScreen(
              mascotController: widget.mascotController,
              companionController: widget.companionController,
              onOpenWallet: widget.onOpenPortfolioTab,
            ),
          ),
        ),
      ),
    ];
  }
}
