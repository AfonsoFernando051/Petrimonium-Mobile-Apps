import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petrimonium_academy/core/constants/app_colors.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/events/app_event.dart';
import 'package:petrimonium_academy/core/events/app_event_bus.dart';
import 'package:petrimonium_academy/core/utils/pet_assets.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/core/widgets/xp_bar.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/rive/pet_rive_companion.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// What real signal chose [HomeCompanionCard]'s message — drives the
/// "Why am I seeing this?" reveal, so the reasoning always matches what
/// actually decided the message rather than a generic disclaimer.
enum HomeCompanionReason { continueLesson, reviewDue, returning }

/// The Pet on Home: the character companion, a sentence about where the
/// learner is, and how their level is coming along.
///
/// Deliberately compact. It used to be two things — a small message card
/// plus a full-height animated pet stage below the primary CTA — and
/// together they out-weighed the one thing Home exists to make obvious
/// (`NextActionCard`). The Pet here carries personality, not hierarchy: it
/// sits above the CTA, stays one block tall, and never becomes a control
/// (tapping it pets the character; it navigates nowhere). It is also not
/// the Mentor — that is its own tab, an AI chat.
class HomeCompanionCard extends StatefulWidget {
  const HomeCompanionCard({
    super.key,
    required this.mascotController,
    required this.petName,
    required this.message,
    required this.reason,
    this.anchor,
  });

  final MascotController mascotController;
  final String petName;
  final String message;
  final HomeCompanionReason reason;

  /// When provided, registers this card's pet art as the Pet's on-screen
  /// position for `PetSpeechBubbleOverlay` to glue its bubble to — see
  /// [PetSpeechBubbleAnchor]. This is Home's only Pet visual, so it is the
  /// anchor the overlay uses whenever Home is the visible tab.
  final PetSpeechBubbleAnchor? anchor;

  @override
  State<HomeCompanionCard> createState() => _HomeCompanionCardState();
}

class _HomeCompanionCardState extends State<HomeCompanionCard> with SingleTickerProviderStateMixin {
  static const double _kPetSize = 92;

  bool _showReason = false;
  late final AnimationController _celebrationController;
  late final Animation<double> _celebration;
  StreamSubscription<AppEvent>? _celebrationEventSubscription;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _celebration = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: Curves.easeIn)), weight: 75),
    ]).animate(_celebrationController);
    _celebrationEventSubscription = AppEventBus.instance.stream.listen((event) {
      if (event is PetEvolvedEvent || event is UserLeveledUpEvent) _celebrate();
    });
  }

  @override
  void dispose() {
    _celebrationEventSubscription?.cancel();
    _celebrationController.dispose();
    super.dispose();
  }

  /// A real level-up or evolution is the one moment this resting card is
  /// allowed to move on its own — never a portfolio or wealth event.
  void _celebrate() {
    if (!mounted || MediaQuery.of(context).disableAnimations) return;
    HapticFeedback.mediumImpact();
    _celebrationController.forward(from: 0);
  }

  void _petTheCharacter() {
    HapticFeedback.lightImpact();
    final mascot = widget.mascotController;
    // Only from rest, so a tap never cuts short a real celebrate/victory
    // moment the rig is already playing.
    if (mascot.animationState == PetAnimationState.idle) {
      mascot.triggerEventAnimation(PetAnimationState.happy, duration: const Duration(milliseconds: 900));
    }
  }

  String get _reasonText => switch (widget.reason) {
    HomeCompanionReason.continueLesson => Translator.translate(AppStrings.homeMentorReasonContinue),
    HomeCompanionReason.reviewDue => Translator.translate(AppStrings.homeMentorReasonReview),
    HomeCompanionReason.returning => Translator.translate(AppStrings.homeMentorReasonReturn),
  };

  /// The itemized citations backing [_reasonText] — what actually fed this
  /// message (lesson consulted, profile/progress signal, internal guide),
  /// so "why am I seeing this?" is auditable rather than a vague sentence.
  List<String> get _reasonSources => switch (widget.reason) {
    HomeCompanionReason.continueLesson => [
      Translator.translate(AppStrings.homeMentorSourceContinue1),
      Translator.translate(AppStrings.homeMentorSourceContinue2),
      Translator.translate(AppStrings.homeMentorSourceContinue3),
    ],
    HomeCompanionReason.reviewDue => [
      Translator.translate(AppStrings.homeMentorSourceReview1),
      Translator.translate(AppStrings.homeMentorSourceReview2),
      Translator.translate(AppStrings.homeMentorSourceReview3),
    ],
    HomeCompanionReason.returning => [
      Translator.translate(AppStrings.homeMentorSourceReturn1),
      Translator.translate(AppStrings.homeMentorSourceReturn2),
      Translator.translate(AppStrings.homeMentorSourceReturn3),
    ],
  };

  /// Aura color reflects the pet's evolution tier, never portfolio
  /// performance (`docs/PRODUCT_VISION.md` §9, §11).
  Color _auraColorFor(int tier) {
    if (tier >= 7) return AppColors.goldenBorder;
    if (tier >= 4) return AppColors.neonViolet;
    return AppColors.neonCyan;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final profile = widget.mascotController.profile;
    final level = LevelCalculator.fromXp(profile.xp);
    final auraColor = _auraColorFor(profile.stage.tier);

    return GlassCard(
      borderColor: tokens.mentor.withValues(alpha: 0.32),
      borderRadius: AppRadii.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPet(auraColor),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.petName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyEmphasis.copyWith(color: tokens.textPrimary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _LevelChip(level: level.level),
                  ],
                ),
                const SizedBox(height: 4),
                Text(widget.message, style: AppTextStyles.label.copyWith(color: tokens.textSecondary, height: 1.4)),
                const SizedBox(height: AppSpacing.md),
                XpBar(progress: level.progress, color: auraColor, height: 4),
                const SizedBox(height: 4),
                Text(
                  '${Translator.translate(AppStrings.homeLevelProgressLabel)} · ${level.xpIntoLevel}/${level.xpForNextLevel} XP',
                  style: AppTextStyles.caption.copyWith(color: tokens.textTertiary, fontSize: 10),
                ),
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: () => setState(() => _showReason = !_showReason),
                  child: Text(
                    Translator.translate(AppStrings.homeMentorWhySeeing),
                    style: AppTextStyles.caption.copyWith(color: tokens.mentor, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_showReason) ...[
                  const SizedBox(height: 4),
                  Text(_reasonText, style: AppTextStyles.caption.copyWith(color: tokens.textTertiary, height: 1.3)),
                  const SizedBox(height: AppSpacing.sm),
                  _SourcesList(sources: _reasonSources),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPet(Color auraColor) {
    final pet = SizedBox(
      width: _kPetSize,
      height: _kPetSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _celebration,
            builder: (context, child) => Container(
              width: _kPetSize,
              height: _kPetSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    auraColor.withValues(alpha: 0.18 + _celebration.value * 0.22),
                    auraColor.withValues(alpha: 0),
                  ],
                  stops: const [0.2, 1],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _celebration,
            builder: (context, child) => Transform.scale(scale: 1 + _celebration.value * 0.1, child: child),
            // `allowStopgapRigs: false`: only characters that satisfy the
            // Companion contract (today the wolf) animate here; dog/owl keep
            // their static portrait.
            child: PetRiveCompanion(
              controller: widget.mascotController,
              size: _kPetSize,
              interactive: false,
              allowStopgapRigs: false,
              fallbackBuilder: (_) => Image.asset(
                PetAssets.imageFor(widget.mascotController.profile.specie.name),
                height: _kPetSize,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(Icons.pets, size: 40, color: context.colors.textTertiary),
              ),
            ),
          ),
        ],
      ),
    );

    // The Pet is a companion, never a control: petting it is affection, so
    // it stays out of the semantics tree rather than being announced as a
    // button (the Pet guardrails in docs/ECOSYSTEM.md).
    return ExcludeSemantics(
      child: GestureDetector(onTap: _petTheCharacter, child: _wrapWithAnchor(pet)),
    );
  }

  Widget _wrapWithAnchor(Widget child) {
    final anchor = widget.anchor;
    if (anchor == null) return child;
    return CompositedTransformTarget(
      link: anchor.link,
      child: KeyedSubtree(key: anchor.boxKey, child: child),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: tokens.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        Translator.translate(AppStrings.homeCompanionLevelChip, params: {'level': '$level'}),
        style: AppTextStyles.caption.copyWith(color: tokens.primary, fontWeight: FontWeight.w700, fontSize: 10),
      ),
    );
  }
}

class _SourcesList extends StatelessWidget {
  const _SourcesList({required this.sources});

  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Translator.translate(AppStrings.homeMentorSourcesLabel).toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: tokens.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          for (final source in sources)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(color: tokens.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      source,
                      style: AppTextStyles.caption.copyWith(color: tokens.textSecondary, fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
