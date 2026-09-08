import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:petrimonium_academy/core/constants/app_colors.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/utils/pet_assets.dart';
import 'package:petrimonium_academy/features/pet/domain/enums/accessory_type.dart';
import 'package:petrimonium_academy/features/pet/domain/enums/pet_accessory_id.dart';
import 'package:petrimonium_academy/features/pet/domain/enums/pet_animation_state.dart';
import 'package:petrimonium_academy/features/pet/domain/enums/pet_evolution_stage.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/animation/pet_animation_engine.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';

/// Renders the gamified pet mascot: an aura layer, the base evolution
/// animation (Lottie, falling back to a static PNG per stage), and any
/// equipped accessories layered on top — driven through
/// [PetAnimationEngine] so the whole stack breathes, reacts and settles as
/// one piece. Tapping/petting the mascot plays a brief `happy` reaction
/// with light haptic feedback.
class PetMascotWidget extends StatefulWidget {
  const PetMascotWidget({
    super.key,
    required this.controller,
    this.size = 220,
    this.interactive = true,
    this.attentive = false,
  });

  final MascotController controller;
  final double size;

  /// Whether tapping the mascot plays its own `happy` reaction. Compact
  /// embeddings (the companion header avatar, the interaction sheet) host
  /// their own tap handler (open the interaction sheet) and set this to
  /// `false` so the two gesture detectors don't compete for the same tap.
  final bool interactive;

  /// Whether the companion's interaction sheet is currently open. While
  /// `true`, the mascot renders [PetAnimationState.listening] regardless of
  /// [MascotController.animationState] — attention to the user takes
  /// visual priority over whatever ambient mood was already playing.
  final bool attentive;

  @override
  State<PetMascotWidget> createState() => _PetMascotWidgetState();
}

class _PetMascotWidgetState extends State<PetMascotWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant PetMascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() => setState(() {});

  void _handlePet() {
    HapticFeedback.lightImpact();
    widget.controller.triggerEventAnimation(
      PetAnimationState.happy,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.controller.profile;
    final effectiveState = widget.attentive ? PetAnimationState.listening : profile.animationState;

    final content = PetAnimationEngine(
      state: effectiveState,
      size: widget.size,
      reducedMotion: MediaQuery.of(context).disableAnimations,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (_showsAura(profile.stage, effectiveState))
              _AuraLayer(stage: profile.stage, size: widget.size),
            _BaseMascotLayer(
              state: effectiveState,
              stage: profile.stage,
              specie: profile.specie.name,
              size: widget.size,
            ),
            for (final entry in profile.equippedAccessories.entries)
              _AccessoryLayer(
                slot: entry.key,
                accessoryId: entry.value,
                size: widget.size,
              ),
          ],
        ),
      ),
    );

    if (!widget.interactive) return content;
    return GestureDetector(onTap: _handlePet, child: content);
  }

  bool _showsAura(PetEvolutionStage stage, PetAnimationState state) {
    return stage.hasAura ||
        state == PetAnimationState.celebrate ||
        state == PetAnimationState.victory;
  }
}

class _AuraLayer extends StatelessWidget {
  const _AuraLayer({required this.stage, required this.size});

  final PetEvolutionStage stage;
  final double size;

  Color get _color {
    if (stage.tier >= 9) return AppColors.goldenBorder;
    if (stage.tier >= 8) return AppColors.neonPurple;
    if (stage.tier >= 7) return AppColors.neonCyan;
    if (stage.tier >= 6) return AppColors.neonViolet;
    return AppColors.neonCyan;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            spreadRadius: size * 0.05,
          ),
        ],
      ),
    );
  }
}

class _BaseMascotLayer extends StatelessWidget {
  const _BaseMascotLayer({
    required this.state,
    required this.stage,
    required this.specie,
    required this.size,
  });

  final PetAnimationState state;
  final PetEvolutionStage stage;

  /// The pet's chosen species — carried all the way to [_EvolutionFallback]
  /// so that when neither the per-state Lottie nor the per-stage PNG exists
  /// yet, the fallback still renders *this* pet's portrait instead of
  /// silently defaulting to the generic dog asset.
  final String? specie;
  final double size;

  @override
  Widget build(BuildContext context) {
    final mascotSize = size * 0.9;
    return Lottie.asset(
      'assets/mascot/animations/${state.assetKey}.json',
      width: mascotSize,
      height: mascotSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _EvolutionFallback(
        stage: stage,
        specie: specie,
        size: mascotSize,
      ),
    );
  }
}

/// Static PNG fallback for a given evolution [stage], used while per-state
/// Lottie animations aren't authored yet. Falls back further to [specie]'s
/// portrait (never a hardcoded species) while per-stage PNGs aren't authored
/// either.
class _EvolutionFallback extends StatelessWidget {
  const _EvolutionFallback({
    required this.stage,
    required this.specie,
    required this.size,
  });

  final PetEvolutionStage stage;
  final String? specie;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/mascot/evolutions/${stage.assetKey}.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        PetAssets.imageFor(specie),
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.pets,
          size: size * 0.6,
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

class _AccessoryLayer extends StatelessWidget {
  const _AccessoryLayer({
    required this.slot,
    required this.accessoryId,
    required this.size,
  });

  final AccessoryType slot;
  final PetAccessoryId accessoryId;
  final double size;

  Alignment get _alignment {
    switch (slot) {
      case AccessoryType.headwear:
        return const Alignment(0, -0.85);
      case AccessoryType.eyewear:
        return const Alignment(0, -0.25);
      case AccessoryType.neckBack:
        return const Alignment(0, 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _alignment,
      child: Image.asset(
        'assets/mascot/accessories/${accessoryId.assetKey}.png',
        width: size * 0.5,
        fit: BoxFit.contain,
        // Accessory art is opt-in and may not exist yet; render nothing
        // rather than a broken-image icon.
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}
